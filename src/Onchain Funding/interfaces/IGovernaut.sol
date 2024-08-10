// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGovernaut {
    function isApprovedProposer(address proposer) external view returns (bool);
}
