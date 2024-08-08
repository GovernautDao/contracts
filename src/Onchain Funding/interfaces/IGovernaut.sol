// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGovernaut {
    function isProposerApproved(address proposer) external view returns (bool);
}
