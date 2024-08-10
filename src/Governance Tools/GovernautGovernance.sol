// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IdentityManager } from "../Identity Management/IdentityManager.sol";

/**
 * @title GovernautGovernance
 * @author Governaut
 * @notice This contract implements a governance system for managing grant-related proposals.
 * @dev This contract extends various OpenZeppelin Governor contracts and integrates with an Identity Manager
 * to ensure only verified identities can participate in governance actions.
 */
contract GovernautGovernance is
    Initializable,
    GovernorUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorStorageUpgradeable,
    GovernorVotesUpgradeable,
    GovernorVotesQuorumFractionUpgradeable
{
    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////
    error UserIsntVerified();
    error IdentityManagerCantBeAddressZero();

    /// @dev Immutable reference to the IdentityManager contract responsible for verifying identities.
    IdentityManager identityManager;

    // @dev Mapping of approved proposals
    mapping(address => bool) public approvedProposers;

    /**
     * @notice Modifier to restrict function access to verified identities only
     * @dev Calls the Identity Manager to check if the sender is verified
     */
    modifier onlyVerifiedIdentity() {
        if (!identityManager.getIsVerified(msg.sender)) {
            revert UserIsntVerified();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IVotes _token, address _identityManagerAddress) public initializer {
        __Governor_init("Governaut");
        __GovernorSettings_init(1 days, 3 weeks, 0);
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorVotesQuorumFraction_init(4);

        if (_identityManagerAddress == address(0)) {
            revert IdentityManagerCantBeAddressZero();
        }
        identityManager = IdentityManager(_identityManagerAddress);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  FUNCTIONS                             ///
    //////////////////////////////////////////////////////////////////////////////
    /**
     * @notice Creates a new proposal
     * @dev Overrides the Governor's propose function to add identity verification
     * @param targets The addresses of the contracts to call
     * @param values The ETH values to send with the calls
     * @param calldatas The call data for each target contract
     * @param description A description of the proposal
     * @return uint256 The ID of the newly created proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        override(GovernorUpgradeable)
        onlyVerifiedIdentity
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    /**
     * @notice Executes a successful proposal
     * @dev Overrides the Governor's execute function to mark proposers as approved
     * @param targets The addresses of the contracts to call
     * @param values The ETH values to send with the calls
     * @param calldatas The call data for each target contract
     * @param descriptionHash The hash of the proposal description
     * @return uint256 The ID of the executed proposal
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        public
        payable
        virtual
        override(GovernorUpgradeable)
        returns (uint256)
    {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        uint256 executedProposalId = super.execute(targets, values, calldatas, descriptionHash);

        // Marks the proposer as approved
        address proposer = proposalProposer(proposalId);
        approvedProposers[proposer] = true;

        return executedProposalId;
    }

    /**
     * @notice Checks if an address is an approved proposer
     * @param proposer The address to check
     * @return bool True if the address is an approved proposer, false otherwise
     */
    function isApprovedProposer(address proposer) public view returns (bool) {
        return approvedProposers[proposer];
    }

    /**
     * @notice Casts a vote on a proposal
     * @dev Overrides the Governor's castVote function to add identity verification
     * @param proposalId The ID of the proposal
     * @param support The vote option (0 = Against, 1 = For, 2 = Abstain)
     * @return uint256 The weight of the cast vote
     */
    function castVote(
        uint256 proposalId,
        uint8 support
    )
        public
        virtual
        override(GovernorUpgradeable)
        onlyVerifiedIdentity
        returns (uint256)
    {
        return super.castVote(proposalId, support);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///      The following functions are overrides required by Solidity.       ///
    //////////////////////////////////////////////////////////////////////////////
    /**
     * @notice Gets the voting delay
     * @return uint256 The number of blocks between proposal creation and voting start
     */
    function votingDelay() public view override(GovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingDelay();
    }

    /**
     * @notice Gets the voting period
     * @return uint256 The number of blocks for which voting is open
     */
    function votingPeriod() public view override(GovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingPeriod();
    }

    /**
     * @notice Calculates the quorum for a specific block number
     * @param blockNumber The block number to check the quorum for
     * @return uint256 The number of votes required for quorum
     */
    function quorum(uint256 blockNumber)
        public
        view
        override(GovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    /**
     * @notice Gets the proposal threshold
     * @return uint256 The minimum number of votes an account must have to create a proposal
     */
    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    /**
     * @notice Internal function to create a proposal
     * @dev Overrides the internal _propose function to use GovernorStorage
     * @param targets The addresses of the contracts to call
     * @param values The ETH values to send with the calls
     * @param calldatas The call data for each target contract
     * @param description A description of the proposal
     * @param proposer The address creating the proposal
     * @return uint256 The ID of the newly created proposal
     */
    function _propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        address proposer
    )
        internal
        override(GovernorUpgradeable, GovernorStorageUpgradeable)
        returns (uint256)
    {
        return super._propose(targets, values, calldatas, description, proposer);
    }
}
