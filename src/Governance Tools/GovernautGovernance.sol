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
    GovernorVotesQuorumFraction
{
    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////
    error IdentityManagerCantBeAddressZero();

    /// @dev Immutable reference to the IdentityManager contract responsible for verifying identities.
    IdentityManager immutable identityManager;

    /// @dev Event emitted when a new proposal is created.
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string indexed description);

    /// @dev Modifier to ensure that only verified identities can execute certain functions.
    modifier onlyVerifiedIdentity() {
        require(identityManager.getIsVerified(msg.sender), "Caller must have a verified identity to propose");
        _;
    }

    /**
     * @param _token Address of the token used for voting.
     * @param _identityManagerAddress Address of the Identity Manager contract.
     * @dev Initializes the Governaut Governance contract with the given parameters.
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
    ///                        External Functions                              ///
    //////////////////////////////////////////////////////////////////////////////
    /**
     * @param targets Array of addresses to which the proposals will be sent.
     * @param values Array of amounts of tokens to send along with the proposals.
     * @param calldatas Array of calldata to pass along with the proposals.
     * @param description Description of the proposal.
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
        external
        onlyVerifiedIdentity
        returns (uint256)
    {
        uint256 proposalId = _propose(targets, values, calldatas, description, proposer);
        emit ProposalCreated(proposalId, proposer, description);
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
