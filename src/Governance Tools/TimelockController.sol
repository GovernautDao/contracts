// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title GovernautTimelock
 * @dev Extends OpenZeppelin's TimelockController for use with the GovernautGovernance contract.
 *
 * Implements a timelock mechanism, enforcing a delay between the queuing and execution of operations. This delay
 * enhances
 * governance security and transparency, allowing stakeholders time to review and react to proposed changes.
 *
 * Deployment and initialization with appropriate parameters are required before linking to the GovernautGovernance
 * contract.
 * The deployed contract's address must be passed as the `_timelock` parameter to the GovernautGovernance constructor.
 */
contract GovernautTimelock is TimelockController {
    /**
     * @dev Initializes the contract with the given parameters.
     *
     * @param minDelay The minimum delay (in seconds) before operations can be executed after being queued.
     * @param proposers The addresses allowed to propose operations.
     * @param executors The addresses allowed to execute operations once the delay has passed.
     * @param admin The address with the authority to grant and revoke roles.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    )
        TimelockController(minDelay, proposers, executors, admin)
    { }
}
