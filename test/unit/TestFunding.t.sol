// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { Funding } from "../../src/Onchain Funding/Funding.sol";

contract TestFunding is Test {
    Funding funding;

    function setup() public {
        funding = new Funding();
    }
}
