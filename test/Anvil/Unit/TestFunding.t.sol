// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Script } from "forge-std/Script.sol";
import { Funding } from "../../../src/Onchain Funding/Funding.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { MockGovernance } from "./mocks/MockGovernance.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Unit tests for Funding.sol.
 * @dev For testing, an ERC20 token with 8 decimals is used, similar to USDC.
 */
contract TestFunding is StdCheats, Test, Script {
    Funding funding;
    ERC20Mock token;
    MockGovernance governance;

    address OWNER = address(123);
    address APPROVED_PROPOSER_1 = address(124);
    address NOT_APROVED_PROPOSER = address(125);
    address INVESTOR_1 = address(126);
    address INVERTOR_2 = address(127);
    address INVESTOR_3 = address(128);
    address INVESTOR_4 = address(129);
    uint256 INITIAL_INVESTMENT = 700;

    error UserIsntAnApprovedProposer();
    error GrantHasEnded();

    function setUp() external {
        vm.startPrank(OWNER);
        token = new ERC20Mock();
        //This governance contract dosent have any logic, a dumb governer
        governance = new MockGovernance();
        funding = new Funding(OWNER, address(governance), address(token));
        governance.approveProposer(APPROVED_PROPOSER_1);
        token.mint(INVESTOR_1, INITIAL_INVESTMENT);
        token.mint(INVERTOR_2, INITIAL_INVESTMENT);
        token.mint(INVESTOR_3, INITIAL_INVESTMENT);
        token.mint(INVESTOR_4, INITIAL_INVESTMENT);
        vm.stopPrank();
        //Some amount of time must be passed since deployment
        vm.warp(800);
    }

    function testConstructorInitialGrant() public view {
        (address projectOwner,,, uint256 goalAmount,,,) = funding.getGrantStatus(0);
        assertEq(projectOwner, address(0));
        assertEq(goalAmount, 0);
    }

    function testUserIsntAnApprovedProposer() public {
        //No non approved proposers can create a grant.
        vm.startPrank(NOT_APROVED_PROPOSER);
        vm.expectRevert(UserIsntAnApprovedProposer.selector);
        funding.createGrant(msg.sender, 500);
    }

    function testCreateGrant() public {
        vm.stopPrank();
        vm.startPrank(APPROVED_PROPOSER_1);
        uint256 grantId = funding.createGrant(APPROVED_PROPOSER_1, 500);
        (
            address projectOwner,
            uint256 startTimestamp,
            uint256 endTimestamp,
            uint256 goalAmount,
            uint256 totalContributed,
            uint256 numberOfClaimsMade,
            uint256 lastClaimTimestamp
        ) = funding.getGrantStatus(grantId);
        assertEq(projectOwner, APPROVED_PROPOSER_1);
        assertGt(startTimestamp, block.timestamp - 10);
        assertLt(endTimestamp, block.timestamp + 22 days);
        assertEq(goalAmount, 500);
        assertEq(totalContributed, 0);
        assertEq(numberOfClaimsMade, 0);
        assertEq(lastClaimTimestamp, 0);
        vm.stopPrank();
    }

    function testGrantHasEnded() public {
        vm.prank(APPROVED_PROPOSER_1);
        uint256 vaultId = funding.createGrant(APPROVED_PROPOSER_1, 100);
        vm.warp(100_000_000_000);
        vm.expectRevert(GrantHasEnded.selector);
        funding.contribute(vaultId, 100);
    }

    function testContribute() public {
        //Create grant
        vm.prank(APPROVED_PROPOSER_1);
        uint256 grantId = funding.createGrant(APPROVED_PROPOSER_1, 300);
        vm.startPrank(INVESTOR_1);
        //Investor contributes
        //Approve tokens from investor for our funding contract to spend.
        token.approve(address(funding), 100);
        funding.contribute(grantId, 100);
        (,,,, uint256 totalContributed,,) = funding.getGrantStatus(grantId);
        assertEq(totalContributed, 100);
        uint256 contributedAmount = funding.getContributionStatus(grantId);
        assertEq(contributedAmount, 100);
        vm.stopPrank();
    }

    function testClaimContributionRefund() public {
        //Create grant
        vm.prank(APPROVED_PROPOSER_1);
        uint256 grantid = funding.createGrant(APPROVED_PROPOSER_1, 800);
        (,, uint256 endTimestamp,,,,) = funding.getGrantStatus(grantid);
        //Investors contribute
        vm.startPrank(INVESTOR_1);
        token.approve(address(funding), 100);
        funding.contribute(grantid, 100);
        vm.stopPrank();
        vm.startPrank(INVERTOR_2);
        token.approve(address(funding), 100);
        funding.contribute(grantid, 100);
        vm.stopPrank();
        vm.startPrank(INVESTOR_3);
        token.approve(address(funding), 100);
        funding.contribute(grantid, 100);
        vm.stopPrank();
        vm.startPrank(INVESTOR_4);
        token.approve(address(funding), 100);
        funding.contribute(grantid, 100);
        vm.stopPrank();
        //Goal is not met and time has passed
        vm.warp(block.timestamp + 31 days);
        vm.prank(INVESTOR_1);
        uint256 amountclaimed1 = funding.claimContributionRefund(grantid);
        vm.prank(INVERTOR_2);
        uint256 amountclaimed2 = funding.claimContributionRefund(grantid);
        vm.prank(INVESTOR_3);
        uint256 amountclaimed3 = funding.claimContributionRefund(grantid);
        vm.prank(INVESTOR_4);
        uint256 amountclaimed4 = funding.claimContributionRefund(grantid);
        assertEq(amountclaimed1 + amountclaimed2 + amountclaimed3 + amountclaimed4, 400);
    }

    function testClaimFunds() public {
        //Create grant
        vm.prank(APPROVED_PROPOSER_1);
        uint256 grantid = funding.createGrant(APPROVED_PROPOSER_1, 800);
        (,, uint256 endTimestamp,,,,) = funding.getGrantStatus(grantid);
        //Investors contribute
        vm.startPrank(INVESTOR_1);
        token.approve(address(funding), 200);
        funding.contribute(grantid, 200);
        vm.stopPrank();
        vm.startPrank(INVERTOR_2);
        token.approve(address(funding), 200);
        funding.contribute(grantid, 200);
        vm.stopPrank();
        vm.startPrank(INVESTOR_3);
        token.approve(address(funding), 200);
        funding.contribute(grantid, 200);
        vm.stopPrank();
        vm.startPrank(INVESTOR_4);
        token.approve(address(funding), 200);
        funding.contribute(grantid, 200);
        vm.stopPrank();
        vm.startPrank(APPROVED_PROPOSER_1);
        //Min 30 days havde to be passed to claim funds
        vm.warp(endTimestamp + 30 days);
        uint256 amountclaimed1 = funding.claimFunds(grantid);
        assertGt(amountclaimed1, 0);
        console.log("claim 1 amount", amountclaimed1);
        vm.warp(block.timestamp + 60 days);
        uint256 amountclaimed2 = funding.claimFunds(grantid);
        console.log("claim 2 amount", amountclaimed2);
        vm.warp(block.timestamp + 60 days);
        uint256 amountclaimed3 = funding.claimFunds(grantid);
        console.log("claim 3 amount", amountclaimed3);
        vm.warp(block.timestamp + 60 days);
        uint256 amountclaimed4 = funding.claimFunds(grantid);
        console.log("claim 4 amount", amountclaimed4);
        assertEq(amountclaimed1 + amountclaimed2 + amountclaimed3 + amountclaimed4, 800);
        assertEq(token.balanceOf(APPROVED_PROPOSER_1), 800);
        vm.stopPrank();
    }
}
