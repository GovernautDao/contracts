// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {GovernautGovernance} from "../../../src/Governance Tools/GovernautGovernance.sol";
import {MockVotes} from "./mocks/MockVotes.sol";
import {MockTimelockController} from "./mocks/MockTimelockController.sol";

contract TestGovernautGovernance is Test {
  GovernautGovernance governautGovernance;
  MockVotes mockVotes;
  MockTimelockController mockTimelockController;

  address IDENTITYMANAGER_ADDRESS = makeAddr("Identity Manager Address");

  function setUp() public {
    // Deploy mock contracts
    mockVotes = new MockVotes();
    mockTimelockController = new MockTimelockController();

    governautGovernance = new GovernautGovernance(
      mockVotes,
      mockTimelockController,
      IDENTITYMANAGER_ADDRESS
    );
  }

  function testDefault() public {}
}
