// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { Funding } from "../../../src/Onchain Funding/Funding.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { MockGovernance } from "./mocks/MockGovernance.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestFunding is Test {
    Funding funding;
    MockERC20 token;
    MockGovernance governance;

    address OWNER = makeAddr("Owner");

    function setUp() public {
        token = new MockERC20(1e18);
        governance = new MockGovernance();
        funding = new Funding(OWNER, address(governance), IERC20(address(token)));
    }

    function testDefault() public { }
}
