// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IGovernautGovernance {
  function approvedProposers(address proposer) external view returns (bool);
}

contract MockGovernance is IGovernautGovernance {
  mapping(address => bool) private _approvedProposers;

  function approvedProposers(
    address proposer
  ) external view override returns (bool) {
    return _approvedProposers[proposer];
  }

  function approveProposer(address proposer) external {
    _approvedProposers[proposer] = true;
  }

  function revokeProposerApproval(address proposer) external {
    _approvedProposers[proposer] = false;
  }

  function isProposerApproved(address proposer) external view returns (bool) {
    return _approvedProposers[proposer];
  }
}
