// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { Governance } from "../../src/Governance Tools/Governance.sol";

contract TestGovernance is Test {
    Governance gov;

    function setUp() public {
        gov = new Governance();
    }
}
