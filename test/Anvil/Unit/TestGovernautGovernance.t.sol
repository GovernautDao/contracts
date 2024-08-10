// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { GovernautGovernance } from "../../../src/Governance Tools/GovernautGovernance.sol";
import { WorldIDIdentityManagerRouterMock } from "./mocks/WorldIDIdentityManagerRouterMock.sol";
import { IdentityManager } from "../../../src/Identity Management/IdentityManager.sol";
import { HelperConfig } from "../../../script/HelperConfig.s.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

contract TestGovernautGovernance is Test {
    GovernautGovernance governautGovernance;
    IdentityManager identityManager;
    HelperConfig helperConfig;
    MockERC20 token;

    address OWNER = makeAddr("Owner");
    address USER_1 = makeAddr("User1");
    address USER_2 = makeAddr("User2");
    address USER_3 = makeAddr("User3");
    address USER_4 = makeAddr("User4");
    address USER_5 = makeAddr("User5");
    address USER_6 = makeAddr("User6");
    address USER_7 = makeAddr("User7");
    address USER_8 = makeAddr("User8");
    address USER_9 = makeAddr("User9");
    address USER_10 = makeAddr("User10");

    function setUp() public {
        helperConfig = new HelperConfig();
        vm.startPrank(OWNER);

        token = new MockERC20();
        // Mint and distribute tokens to users
        token.mint(USER_1, 1000 * 10 ** 18); // Adjust the amount as needed
        token.mint(USER_2, 10_000 * 10 ** 18);
        token.mint(USER_3, 10_000 * 10 ** 18);
        token.mint(USER_4, 10_000 * 10 ** 18);
        token.mint(USER_5, 10_000 * 10 ** 18);
        token.mint(USER_6, 10_000 * 10 ** 18);
        token.mint(USER_7, 10_000 * 10 ** 18);
        token.mint(USER_8, 10_000 * 10 ** 18);
        token.mint(USER_9, 10_000 * 10 ** 18);
        token.mint(USER_10, 10_000 * 10 ** 18);

        identityManager = new IdentityManager(
            OWNER,
            helperConfig.getAnvilConfig()._WorldcoinRouterAddress,
            helperConfig.getAnvilConfig()._appid,
            helperConfig.getAnvilConfig()._actionId
        );
        governautGovernance = new GovernautGovernance(token, address(identityManager));
        vm.stopPrank();
    }

    modifier DelegateVotingPower() {
        vm.startPrank(USER_1);
        token.delegate(USER_1);
        vm.stopPrank();
        vm.startPrank(USER_2);
        token.delegate(USER_2);
        vm.stopPrank();
        vm.startPrank(USER_3);
        token.delegate(USER_3);
        vm.stopPrank();
        vm.startPrank(USER_4);
        token.delegate(USER_4);
        vm.stopPrank();
        vm.startPrank(USER_5);
        token.delegate(USER_5);
        vm.stopPrank();
        vm.startPrank(USER_6);
        token.delegate(USER_6);
        vm.stopPrank();
        vm.startPrank(USER_7);
        token.delegate(USER_7);
        vm.stopPrank();
        vm.startPrank(USER_8);
        token.delegate(USER_8);
        vm.stopPrank();
        vm.startPrank(USER_9);
        token.delegate(USER_9);
        vm.stopPrank();
        vm.startPrank(USER_10);
        token.delegate(USER_10);
        vm.stopPrank();

        // Advance block timestamp to ensure delegations are active
        vm.warp(block.timestamp + 1);
        _;
    }

    function testUnverifiedProposeFunction() public {
        // Attempt to propose with an unverified identity
        vm.startPrank(USER_1);
        vm.expectRevert(GovernautGovernance.UserIsntVerified.selector);
        governautGovernance.propose(new address[](0), new uint256[](0), new bytes[](0), "Project Proposal");
        vm.stopPrank();
    }

    function testVerifiedProposeFunctionCreatesProposal() public {
        vm.startPrank(USER_1);
        // Verify USER_1 for testing purposes
        identityManager.dumbVerify();
        bool verified = identityManager.getIsVerified(USER_1);
        assertEq(verified, true, "USER_1 should be verified");

        // Prepare proposal details
        address[] memory targets = new address[](1);
        targets[0] = address(this); // Example target, can be any valid address
        uint256[] memory values = new uint256[](1);
        values[0] = 0; // Example value
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature(""); // Example call data
        string memory description = "Test Proposal";

        // Propose and retrieve proposal ID
        uint256 proposalId = governautGovernance.propose(targets, values, calldatas, description);
        vm.stopPrank();

        // Assert proposal creation
        assertTrue(proposalId > 0);

        // Retrieve and assert proposal details
        (
            address[] memory retTargets,
            uint256[] memory retValues,
            bytes[] memory retCalldatas,
            bytes32 retDescriptionHash
        ) = governautGovernance.proposalDetails(proposalId);

        assertEq(retTargets.length, targets.length);
        assertEq(retTargets[0], targets[0]);
        assertEq(retValues[0], values[0]);
        assertEq(retCalldatas[0], calldatas[0]);
        assertEq(retDescriptionHash, keccak256(bytes(description)));
    }

    function testProposalExecution() public DelegateVotingPower {
        // Setup: Create and vote on a proposal as verified users
        vm.startPrank(USER_1);
        identityManager.dumbVerify(); // Verify USER_1
        uint256 proposalId =
            governautGovernance.propose(new address[](1), new uint256[](1), new bytes[](1), "Execute Proposal");
        vm.stopPrank();

        // Ensure we're past the votingDelay but within the votingPeriod
        vm.warp(block.timestamp + governautGovernance.votingDelay() + 1); // Warp to just after the start of the voting
            // period

        // Simulation of other users voting to meet quorum
        address[] memory users = new address[](10);
        users[0] = USER_1;
        users[1] = USER_2;
        users[2] = USER_3;
        users[3] = USER_4;
        users[4] = USER_5;
        users[5] = USER_6;
        users[6] = USER_7;
        users[7] = USER_8;
        users[8] = USER_9;
        users[9] = USER_10;

        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            identityManager.dumbVerify(); // Verify each user
            governautGovernance.castVote(proposalId, 1); // Each user votes in favor
            vm.stopPrank();
        }

        // Advance time to simulate the end of the voting period
        vm.warp(block.timestamp + governautGovernance.votingPeriod() + 1); // Warp to just after the end of the voting
            // period

        // Test: Execute the proposal
        governautGovernance.execute(proposalId);

        // Verify: Check if the approvedProposers mapping is updated correctly
        bool isApproved = governautGovernance.isApprovedProposer(USER_1);
        assertTrue(isApproved, "Proposer should be approved after successful proposal execution.");
    }

    function testQuorumRequirements() public DelegateVotingPower {
        // Setup: Create a proposal
        vm.startPrank(USER_1);
        identityManager.dumbVerify();
        uint256 proposalId =
            governautGovernance.propose(new address[](1), new uint256[](1), new bytes[](1), "Quorum Test");
        vm.stopPrank();

        // Advance to voting period
        vm.warp(block.timestamp + governautGovernance.votingDelay() + 1);

        // Have only 2 users vote (assuming this is below quorum)
        address[] memory voters = new address[](1);
        voters[0] = USER_1;

        for (uint256 i = 0; i < voters.length; i++) {
            vm.startPrank(voters[i]);
            identityManager.dumbVerify();
            governautGovernance.castVote(proposalId, 1);
            vm.stopPrank();
        }

        // Advance to end of voting period
        vm.warp(block.timestamp + governautGovernance.votingPeriod() + 1);

        // Attempt to execute the proposal
        vm.expectRevert(); // Expect this to fail due to not meeting quorum
        governautGovernance.execute(proposalId);
    }

    function testProposalThreshold() public {
        // Assuming there's a non-zero proposal threshold
        uint256 threshold = governautGovernance.proposalThreshold();

        if (threshold > 0) {
            // Setup: Mint just below the threshold amount to USER_1
            vm.startPrank(OWNER);
            token.mint(USER_1, threshold - 1);
            vm.stopPrank();

            // Attempt to propose with insufficient tokens
            vm.startPrank(USER_1);
            identityManager.dumbVerify();
            vm.expectRevert(); // Expect this to fail due to insufficient tokens
            governautGovernance.propose(new address[](1), new uint256[](1), new bytes[](1), "Threshold Test");
            vm.stopPrank();
        }
    }

    function testVotingPeriodConstraints() public DelegateVotingPower {
        // Setup: Create a proposal
        vm.startPrank(USER_1);
        identityManager.dumbVerify();
        uint256 proposalId =
            governautGovernance.propose(new address[](1), new uint256[](1), new bytes[](1), "Voting Period Test");
        vm.stopPrank();

        // Attempt to vote before voting delay has passed
        vm.startPrank(USER_2);
        identityManager.dumbVerify();
        vm.expectRevert(); // Expect this to fail as voting hasn't started
        governautGovernance.castVote(proposalId, 1);
        vm.stopPrank();

        // Advance past voting period
        vm.warp(block.timestamp + governautGovernance.votingDelay() + governautGovernance.votingPeriod() + 1);

        // Attempt to vote after voting period has ended
        vm.startPrank(USER_3);
        identityManager.dumbVerify();
        vm.expectRevert(); // Expect this to fail as voting has ended
        governautGovernance.castVote(proposalId, 1);
        vm.stopPrank();
    }

    function testDoubleVoting() public DelegateVotingPower {
        // Setup: Create a proposal
        vm.startPrank(USER_1);
        identityManager.dumbVerify();
        uint256 proposalId =
            governautGovernance.propose(new address[](1), new uint256[](1), new bytes[](1), "Double Voting Test");
        vm.stopPrank();

        // Advance to voting period
        vm.warp(block.timestamp + governautGovernance.votingDelay() + 1);

        // Vote once
        vm.startPrank(USER_2);
        identityManager.dumbVerify();
        governautGovernance.castVote(proposalId, 1);

        // Attempt to vote again
        vm.expectRevert(); // Expect this to fail as USER_2 has already voted
        governautGovernance.castVote(proposalId, 1);
        vm.stopPrank();
    }
}
