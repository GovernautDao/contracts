// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { Governance } from "../../src/Governance.sol";

contract TestGovernance is Test {
    Governance gov;

    address IDENTITY_MANAGER = makeAddr("IDENTITY_MANAGER");

    function setUp() public {
        gov = new Governance(IDENTITY_MANAGER);
    }
}
