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

    function setUp() public {
        helperConfig = new HelperConfig();
        vm.startPrank(OWNER);

        token = new MockERC20();
        // Mint and distribute tokens to users
        token.mint(USER_1, 1000 * 10 ** 18); // Adjust the amount as needed
        token.mint(USER_2, 1000 * 10 ** 18);
        token.mint(USER_3, 1000 * 10 ** 18);
        token.mint(USER_4, 1000 * 10 ** 18);
        token.mint(USER_5, 1000 * 10 ** 18);

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
        address[] memory users = new address[](3);
        users[0] = USER_1;
        users[1] = USER_2;
        users[2] = USER_3;

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
}
