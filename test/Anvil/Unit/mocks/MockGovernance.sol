// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IGovernautGovernance {
    function isApprovedProposer(address proposer) external view returns (bool);
}

contract MockGovernance is IGovernautGovernance {
    mapping(address => bool) private _approvedProposers;

    function isApprovedProposer(address proposer) external view override returns (bool) {
        return _approvedProposers[proposer];
    }
}
