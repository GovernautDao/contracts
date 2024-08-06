// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract MockVotes is IVotes {
    // Implement all methods from the IVotes interface
    function getVotes(address account) external view override returns (uint256) {
        // Mock implementation or logic for testing
        return 0;
    }

    function getPastVotes(address account, uint256 timepoint) external view override returns (uint256) {
        // Mock implementation or logic for testing
        return 0;
    }

    function getPastTotalSupply(uint256 timepoint) external view override returns (uint256) {
        // Mock implementation or logic for testing
        return 0;
    }

    function delegates(address account) external view override returns (address) {
        // Mock implementation or logic for testing
        return address(0);
    }

    function delegate(address delegatee) external override {
        // Mock implementation or logic for testing
        // This function would normally update the delegate for the msg.sender
    }

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
    {
        // Mock implementation or logic for testing
        // This function would normally update the delegate for the signer of the message
    }
}
