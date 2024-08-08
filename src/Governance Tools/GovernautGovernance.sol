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
import { IdentityManager } from "../Identity Management/IdentityManager.sol";

/**
 * @title GovernautGovernance
 * @author Governaut
 * @dev Implements a governance system leveraging OpenZeppelin's Governor contracts. It is designed to manage proposals
 * related to grants, including their submission, review, approval, and disbursement. The contract integrates with an
 * Identity Manager to ensure that only verified identities can propose actions.
 */
contract GovernautGovernance is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorStorage,
    GovernorVotes,
    GovernorVotesQuorumFraction
{
    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////
    error IdentityManagerCantBeAddressZero();
    error UserIsntVerified();

    /// @dev Immutable reference to the IdentityManager contract responsible for verifying identities.
    IdentityManager immutable identityManager;

    /// @dev Mapping from proposer address to whether the proposer has been approved.
    mapping(address => bool) public approvedProposers;

    /// @dev Mapping from proposal ID to proposer address.
    mapping(uint256 => address) private _proposalIdToProposer;

    /// @dev Event emitted when a new proposal is created.
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string indexed description);

    /// @dev Modifier to ensure that only verified identities can execute certain functions.
    modifier onlyVerifiedIdentity() {
        if (!identityManager.getIsVerified(msg.sender)) {
            revert UserIsntVerified();
        }
        _;
    }

    /**
     * @dev Sets up the governance contract with necessary settings and initializes the reference to the Identity
     * Manager.
     * @param _token The token used for voting.
     * @param _identityManagerAddress The address of the Identity Manager contract.
     */
    constructor(
        IVotes _token,
        address _identityManagerAddress
    )
        Governor("Governaut")
        GovernorSettings(1 days, 3 weeks, 0e18)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
    {
        if (_identityManagerAddress == address(0)) {
            revert IdentityManagerCantBeAddressZero();
        }
        identityManager = IdentityManager(_identityManagerAddress);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                        External/Public Functions                       ///
    //////////////////////////////////////////////////////////////////////////////
    /**
     * @notice Creates a new proposal.
     * @dev Only verified identities can propose. Emits a `ProposalCreated` event upon success.
     * @param targets The addresses to which the proposals will be sent.
     * @param values The amounts of tokens to send with the proposals.
     * @param calldatas The calldata to pass with the proposals.
     * @param description A description of the proposal.
     * @param proposer The address of the proposer.
     * @return proposalId The ID of the newly created proposal.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        address proposer
    )
        external
        onlyVerifiedIdentity
        returns (uint256)
    {
        uint256 proposalId = _propose(targets, values, calldatas, description, proposer);
        _proposalIdToProposer[proposalId] = proposer;
        emit ProposalCreated(proposalId, proposer, description);
        return proposalId;
    }

    /**
     * @notice Executes a proposal.
     * @dev Marks the proposer as approved upon successful execution.
     * @param targets The addresses targeted by the proposal.
     * @param values The values involved in the proposal.
     * @param calldatas The calldata to execute with the proposal.
     * @param descriptionHash A hash of the proposal's description.
     * @return proposalId The ID of the executed proposal.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        public
        payable
        override
        returns (uint256)
    {
        // Execute the proposal using the inherited execute logic
        uint256 proposalId = super.execute(targets, values, calldatas, descriptionHash);

        // Retrieve the proposer's address using the proposal ID
        address proposer = _proposalIdToProposer[proposalId];
        // Mark the proposer as approved
        approvedProposers[proposer] = true;

        return proposalId;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                        Internal Functions                              ///
    //////////////////////////////////////////////////////////////////////////////
    // The following functions are overrides required by Solidity.
    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

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
}
