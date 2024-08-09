// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorStorage} from "@openzeppelin/contracts/governance/extensions/GovernorStorage.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {IdentityManager} from "../Identity Management/IdentityManager.sol";

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
  uint48 public constant VOTING_DELAY = 1;
  uint32 public constant VOTING_PERIOD = 5;

  error IdentityManagerCantBeAddressZero();
  error UserIsntVerified();

  /// @dev Immutable reference to the IdentityManager contract responsible for verifying identities.
  IdentityManager immutable identityManager;

  /// @dev Mapping from proposer address to whether the proposer has been approved.
  mapping(address => bool) public approvedProposers;

  /// @dev Mapping from proposal ID to proposer address.
  mapping(uint256 => address) private _proposalIdToProposer;

  /// @dev Event emitted when a new proposal is created.
  event ProposalCreated(
    uint256 indexed proposalId,
    address indexed proposer,
    string indexed description
  );

  /// @dev Event emitted when a proposal is ended.
  event ProposalEnded(
    uint256 indexed proposalId,
    address indexed proposer,
    bool executed
  );

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
    GovernorSettings(VOTING_DELAY, VOTING_PERIOD, 0)
    GovernorVotes(_token)
    GovernorVotesQuorumFraction(4) // suggested by openzeppelin
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
   * @dev targets : token address in this case(the token contract will be interacted with and funds will go to passed proposer)
   * @param values The amounts of tokens to send with the proposals.
   * @param calldatas The calldata to pass with the proposals.
   * @param description A description of the proposal.
   * @param proposer The address of the proposer.
   * @return proposalId The ID of the newly created proposal.
   */
  function createProposal(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description,
    address proposer
  ) external onlyVerifiedIdentity returns (uint256) {
    uint256 proposalId = _propose(
      targets,
      values,
      calldatas,
      description,
      proposer
    );
    _proposalIdToProposer[proposalId] = proposer;
    emit ProposalCreated(proposalId, proposer, description);
    return proposalId;
  }

  function queueProposal(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 description
  ) external onlyVerifiedIdentity returns (uint256) {
    uint256 _proposalId = super._queueOperations(
      proposalId,
      targets,
      values,
      calldatas,
      description
    );
    return _proposalId;
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
  ) public payable override returns (uint256) {
    uint256 proposalId = super.execute(
      targets,
      values,
      calldatas,
      descriptionHash
    );

    // Retrieve the proposer's address using the proposal ID
    address proposer = _proposalIdToProposer[proposalId];

    // Mark the proposer as approved
    approvedProposers[proposer] = true;

    // Emit the ProposalEnded event indicating the proposal was executed
    emit ProposalEnded(proposalId, proposer, true);

    return proposalId;
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///                        Internal Functions                              ///
  //////////////////////////////////////////////////////////////////////////////
  // The following functions are overrides required by Solidity.

  function quorum(
    uint256 blockNumber
  )
    public
    view
    override(Governor, GovernorVotesQuorumFraction)
    returns (uint256)
  {
    return super.quorum(blockNumber);
  }

  function proposalThreshold()
    public
    view
    override(Governor, GovernorSettings)
    returns (uint256)
  {
    return super.proposalThreshold();
  }

  function _propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description,
    address proposer
  ) internal override(Governor, GovernorStorage) returns (uint256) {
    return super._propose(targets, values, calldatas, description, proposer);
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///                        Internal Functions                              ///
  //////////////////////////////////////////////////////////////////////////////
  /**
   *
   * @param proposer To check if a proposer is approved
   */
  function isProposerApproved(address proposer) public view returns (bool) {
    return approvedProposers[proposer];
  }

  /**
   * @notice getter for checking current state of a proposal
   * @notice 0:Pending, 1:Active, 2:Canceled, 3:Defeated, 4:Succeeded, 5:Queued, 6:Expired, 7:Executed
   * @dev the Proposal State is an enum data type, defined in the IGovernor contract.
   * @param _proposalId id of the proposal to check the state
   */
  function getProposalState(
    uint256 _proposalId
  ) public view returns (ProposalState) {
    return super.state(_proposalId);
  }

  function getVotingDelay() public pure returns (uint256) {
    return VOTING_DELAY;
  }

  function getVotingPeriod() public pure returns (uint256) {
    return VOTING_PERIOD;
  }
}
