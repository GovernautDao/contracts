// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {console} from "forge-std/Console.sol";
import {GovernautGovernance} from "../../../src/Governance Tools/GovernautGovernance.sol";
import {MockVotes} from "./mocks/MockVotes.sol";
import {MockTimelockController} from "./mocks/MockTimelockController.sol";
import {WorldIDIdentityManagerRouterMock} from "./mocks/WorldIDIdentityManagerRouterMock.sol";
import {IdentityManager} from "../../../src/Identity Management/IdentityManager.sol";
import {Funding} from "../../../src/Onchain Funding/Funding.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract TestGovernautGovernance is Test {
  address owner = address(124); //owner
  address user1 = address(125); //proposer
  address user2 = address(126); //voter

  //params for governer function calls
  address[] public targets;
  uint256[] public values;
  bytes[] public calldatas;

  GovernautGovernance governautGovernance;
  //gotta fix this mock votes
  MockVotes mockVotes;
  MockTimelockController mockTimelockController;
  IdentityManager identityManager;
  HelperConfig helperConfig;
  Funding funding;
  MockERC20 fundingToken;

  function setUp() public {
    // Deploy mock contracts
    mockVotes = new MockVotes();
    fundingToken = new MockERC20(5000);
    mockTimelockController = new MockTimelockController();
    helperConfig = new HelperConfig();
    vm.startPrank(owner);
    identityManager = new IdentityManager(
      owner,
      helperConfig.getAnvilConfig()._WorldcoinRouterAddress,
      helperConfig.getAnvilConfig()._appid,
      helperConfig.getAnvilConfig()._actionId
    );
    governautGovernance = new GovernautGovernance(
      mockVotes,
      address(identityManager)
    );
    funding = new Funding(
      owner,
      address(governautGovernance),
      address(fundingToken)
    );
    //delegate votes, gotta fix this too
    mockVotes.delegate(user2);
    vm.stopPrank();
  }

  function testCreateProposal() public {
    vm.startPrank(user1);
    //only for testing this contract, this function dosent do anything, a dumb verifier for world id
    identityManager.dumbVerify();
    bool verified = identityManager.getIsVerified(user1);
    assertEq(verified, true);

    //create proposal prep
    bytes memory encodedFunctionCall = abi.encodeWithSignature(
      "funding.createGrant(address,uint256)",
      user1,
      100
    );
    targets.push(address(funding));
    values.push(0);
    calldatas.push(encodedFunctionCall);

    //1.create proposal
    uint256 proposalId = governautGovernance.createProposal(
      targets,
      values,
      calldatas,
      "description",
      msg.sender
    );
    console.log("proposal successfully created, id is", proposalId);
    assertGt(proposalId, 0);
    uint256 stateBeforeVotingDelay = uint256(
      governautGovernance.getProposalState(proposalId)
    );
    assertEq(stateBeforeVotingDelay, 0);
    console.log("stateBeforeVotingDelay", stateBeforeVotingDelay);
    uint256 votingDelay = governautGovernance.getVotingDelay();
    console.log("voting delay in blocks", votingDelay);
    console.log(
      "Extending block number for testing this proposal! current timestamp",
      block.number
    );

    //voting delay reached
    vm.roll(block.number + uint32(votingDelay) + 1);
    console.log("block number extended! new block number", block.number);
    uint256 stateAfterVotingDelay = uint256(
      governautGovernance.getProposalState(proposalId)
    );
    console.log("stateAfterVotingDelay", stateAfterVotingDelay);
    assertEq(stateAfterVotingDelay, 1); // this must be 1 , but it is still 0
    vm.stopPrank();
    string memory reason = "I like 77.";
    vm.prank(user2); // delegatee
    governautGovernance.castVoteWithReason(proposalId, uint8(1), reason);
    uint256 stateBeforeVotingPeriod = uint256(
      governautGovernance.getProposalState(proposalId)
    );
    console.log("stateBeforeVotingPeriod", stateBeforeVotingPeriod);
    uint256 votingPeriod = governautGovernance.getVotingPeriod();
    console.log("before voting period block number", block.number);

    //voting period reached
    vm.roll(block.number + uint32(votingPeriod) + 3);
    uint256 stateAfterVotingPeriod = uint256(
      governautGovernance.getProposalState(proposalId)
    );
    console.log("after voting period block number", block.number);
    console.log("stateAfterVotingPeriod", stateAfterVotingPeriod);
    assertEq(stateAfterVotingPeriod, 3);
    vm.startPrank(user1);

    // uint256 _proposalId = governautGovernance.queueProposal(
    //   proposalId,
    //   targets,
    //   values,
    //   calldatas,
    //   keccak256(abi.encodePacked("description"))
    // );

    // uint256 stateAfterQueued = uint256(
    //   governautGovernance.getProposalState(proposalId)
    // );
    // console.log("stateAfterQueued", stateAfterQueued);
    // assertEq(stateAfterQueued, 5);
    // gotta test this
    // governautGovernance.execute(
    //   targets,
    //   values,
    //   calldatas,
    //   keccak256(abi.encodePacked("description"))
    // );
    // uint256 stateAfterExecuted = uint256(
    //   governautGovernance.getProposalState(proposalId)
    // );
    // console.log("stateAfterExecuted", stateAfterExecuted);
    vm.stopPrank();
  }
}
