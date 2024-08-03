// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { IdentityManager } from "../../src/IdentityManager.sol";

contract TestIdentityManager is Test {
    IdentityManager idManager;

    function setUp() public {
        idManager = new IdentityManager();
    }
}
