// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
import { GovernorSettings } from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import { GovernorCountingSimple } from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import { GovernorStorage } from "@openzeppelin/contracts/governance/extensions/GovernorStorage.sol";
import { GovernorVotes } from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import { IVotes } from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import { GovernorVotesQuorumFraction } from
    "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import { GovernorTimelockControl } from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { IdentityManager } from "../Identity Management/IdentityManager.sol";

/**
 * @title GovernautGovernance
 * @author Governaut
 * @notice This contract implements a governance system using OpenZeppelin's Governor contracts.
 * Manages grants, including submission, reviews, approval, and disbursement processes.
 * It could integrate with Optimism's infrastructure for efficient transaction processing.
 * It integrates with an Identity Manager to verify the identities of those proposing actions.
 */
contract GovernautGovernance is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorStorage,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    /// @notice Thrown when attempting to propose with an address of zero.
    error IdentityManagerCantBeAddressZero();

    /// @dev Immutable reference to the IdentityManager contract responsible for verifying identities.
    IdentityManager immutable identityManager;

    /// @dev Mapping to store approved proposers.
    mapping(address => bool) private approvedProposers;

    /// @dev Mapping to store proposer's address for each proposal ID
    mapping(uint256 => address) private _proposalProposers;

    /// @dev Event emitted when a new proposal is created.
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string indexed description);

    /// @dev Modifier to ensure that only verified identities can execute certain functions.
    // modifier onlyVerifiedIdentity() {
    //     require(identityManager.isVerified(msg.sender), "Caller must have a verified identity to propose");
    //     _;
    // }

    /**
     * @param _token Address of the token used for voting.
     * @param _timelock Address of the timelock controller.
     * @param _identityManagerAddress Address of the Identity Manager contract.
     * @dev Initializes the Governaut Governance contract with the given parameters.
     */
    constructor(
        IVotes _token,
        TimelockController _timelock,
        address _identityManagerAddress
    )
        Governor("Governaut")
        GovernorSettings(1 days, 1 weeks, 10e18)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {
        if (_identityManagerAddress == address(0)) {
            revert IdentityManagerCantBeAddressZero();
        }
        identityManager = IdentityManager(_identityManagerAddress);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                        External Functions                              ///
    //////////////////////////////////////////////////////////////////////////////
    /**
     * @param targets Array of addresses to which the proposals will be sent.
     * @param values Array of amounts of tokens to send along with the proposals.
     * @param calldatas Array of calldata to pass along with the proposals.
     * @param description Description of the proposal.
     * @param proposer Address of the proposer.
     * @return Proposal ID.
     * @dev Calls the `_propose` function to create a new proposal.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        address proposer
    )
        external //onlyVerifiedIdentity
        returns (uint256)
    {
        uint256 proposalId = _propose(targets, values, calldatas, description, proposer);
        _proposalProposers[proposalId] = proposer;
        emit ProposalCreated(proposalId, proposer, description);
        return proposalId;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                        Internal Functions                              ///
    //////////////////////////////////////////////////////////////////////////////
    function approveProposer(address proposer) internal {
        approvedProposers[proposer] = true;
    }
    /**
     * @dev Creates a new proposal with the given details.
     * @param targets Addresses to which the proposals will be sent.
     * @param values Amounts of tokens to send along with the proposals.
     * @param calldatas Calldata to pass along with the proposals.
     * @param description Hash of the proposal description.
     * @return Proposal ID.
     */

    function _propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        address proposer
    )
        internal
        override(Governor, GovernorStorage)
        returns (uint256)
    {
        return super._propose(targets, values, calldatas, description, proposer);
    }

    /**
     * @dev Queues operations defined in a proposal for execution.
     * @param proposalId ID of the proposal.
     * @param targets Addresses to which the operations will be sent.
     * @param values Amounts of tokens to send along with the operations.
     * @param calldatas Calldata to pass along with the operations.
     * @param descriptionHash Hash of the proposal description.
     * @return Queue ID.
     */
    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint48)
    {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }
    /**
     * @dev Executes operations defined in a proposal.
     * @param proposalId ID of the proposal.
     * @param targets Addresses to which the operations will be sent.
     * @param values Amounts of tokens to send along with the operations.
     * @param calldatas Calldata to pass along with the operations.
     * @param descriptionHash Hash of the proposal description.
     */

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(Governor, GovernorTimelockControl)
    {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
        address proposerAddress = _proposalProposers[proposalId];
        approveProposer(proposerAddress);
    }

    /**
     * @dev Cancels operations defined in a proposal.
     * @param targets Addresses to which the operations will be sent.
     * @param values Amounts of tokens to send along with the operations.
     * @param calldatas Calldata to pass along with the operations.
     * @param descriptionHash Hash of the proposal description.
     * @return Cancellation transaction hash.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                        Internal View                                   ///
    //////////////////////////////////////////////////////////////////////////////
    /**
     * @dev Returns the executor address for proposals.
     * @return Executor address.
     */
    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                        Public/External View                            ///
    //////////////////////////////////////////////////////////////////////////////

    // Overrides required by Solidity for integrating various extensions
    /// @dev Returns the minimum time between consecutive votes.
    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    /// @dev Returns the duration after which a vote becomes eligible for execution.
    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    /// @dev Calculates the quorum based on the current block number.
    function quorum(uint256 blockNumber)
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    /// @dev Returns the current state of a proposal.
    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /// @dev Determines whether a proposal needs to be queued before execution.
    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    /// @dev Returns the minimum number of votes required to submit a proposal.
    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }
}
