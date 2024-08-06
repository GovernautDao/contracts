// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IGovernautGovernance {
    function approvedProposers(address) external view returns (bool);
}
