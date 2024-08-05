// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { GovernautGovernance } from "../../src/Governance Tools/GovernautGovernance.sol";

contract TestGovernautGovernance is Test {
    GovernautGovernance governautGovernance;

    function setUp() public {
        governautGovernance = new GovernautGovernance();
    }

    function testDefault() public { }
}
