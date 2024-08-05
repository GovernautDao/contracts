// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { GovernautGovernance } from "../../src/Governance Tools/GovernautGovernance.sol";

contract TestGovernautGovernance is Test {
    GovernautGovernance governautGovernance;

    address TOKEN = makeAddr("IVotes Token");
    address TIMELOCKCONTROLLER = makeAddr("TimelockController");
    address IDENTITYMANAGER = makeAddr("IdentityManager");

    function setUp() public {
        governautGovernance = new GovernautGovernance(TOKEN, TIMELOCKCONTROLLER, IDENTITYMANAGER);
    }

    function testDefault() public { }
}
