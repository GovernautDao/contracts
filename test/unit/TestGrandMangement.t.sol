// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { GrantManagement } from "../../src/Governance Tools/GrantManagement.sol";

contract TestGrantManagement is Test {
    GrantManagement gManagement;

    function setUp() public {
        gManagement = new GrantManagement();
    }
}
