// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract MockTimelockController is TimelockController {
    constructor()
        TimelockController(
            1, // minDelay
            new address[](0), // proposers
            new address[](0), // executors
            address(0) // admin, set to zero address to disable
        )
    { }

    // You can override methods or add mock methods here for testing purposes
}
