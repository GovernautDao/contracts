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

    // @dev Mapping of approved proposals
    mapping(address => bool) public approvedProposers;

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
        GovernorSettings(1 days, 3 weeks, 0)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4) // suggested by openzeppelin
    {
        if (_identityManagerAddress == address(0)) {
            revert IdentityManagerCantBeAddressZero();
        }
        identityManager = IdentityManager(_identityManagerAddress);
    }

    /**
     * @notice Overrides the propose function to add verification check
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        override(Governor)
        onlyVerifiedIdentity
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        public
        payable
        virtual
        override(Governor)
        returns (uint256)
    {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        uint256 executedProposalId = super.execute(targets, values, calldatas, descriptionHash);

        // Mark the proposer as approved
        address proposer = proposalProposer(proposalId);
        approvedProposers[proposer] = true;

        return executedProposalId;
    }

    function isApprovedProposer(address proposer) public view returns (bool) {
        return approvedProposers[proposer];
    }
    /**
     * @notice Overrides the castVote function to add verification check
     */

    function castVote(
        uint256 proposalId,
        uint8 support
    )
        public
        virtual
        override(Governor)
        onlyVerifiedIdentity
        returns (uint256)
    {
        return super.castVote(proposalId, support);
    }

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
