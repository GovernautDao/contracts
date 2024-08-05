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
 * @title Governaut Governance
 * @author Governaut
 * @notice This contract integrates OpenZeppelin's governance components to manage proposals, voting, and timelocked
 * operations within the Governaut ecosystem.
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
    /// @dev Immutable reference to the IdentityManager contract responsible for verifying identities.
    IdentityManager immutable identityManager;

    /// @dev Modifier to ensure that only verified identities can execute certain functions.
    // modifier onlyVerifiedIdentity() {
    //     require(identityManager.isVerified(msg.sender), "Caller is not a verified identity");
    //     _;
    // }

    /**
     * @notice Constructs the GovernautGovernance contract.
     * @param _token Address of the token used for voting rights.
     * @param _timelock Address of the TimelockController contract.
     * @param _identityManagerAddress Address of the IdentityManager contract.
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
        identityManager = IdentityManager(_identityManagerAddress);
    }

    // Overrides required by Solidity for integrating various extensions
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

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    /**
     * @dev Internal function to propose new actions.
     * @param targets Addresses of the contracts to call.
     * @param values Amounts of wei to send to the targets.
     * @param calldatas Calldata to pass to the target contracts.
     * @param description Description of the proposal.
     * @param proposer Address of the proposer.
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
     * @dev Internal function to queue operations for execution after a timelock period.
     * @param proposalId ID of the proposal to queue.
     * @param targets Addresses of the contracts to call.
     * @param values Amounts of wei to send to the targets.
     * @param calldatas Calldata to pass to the target contracts.
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
     * @dev Internal function to execute queued operations immediately.
     * @param proposalId ID of the proposal to execute.
     * @param targets Addresses of the contracts to call.
     * @param values Amounts of wei to send to the targets.
     * @param calldatas Calldata to pass to the target contracts.
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
    }

    /**
     * @dev Internal function to cancel queued operations.
     * @param targets Addresses of the contracts to call.
     * @param values Amounts of wei to send to the targets.
     * @param calldatas Calldata to pass to the target contracts.
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

    /**
     * @dev Returns the executor address for proposals.
     * @return Executor address.
     */
    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }
}
