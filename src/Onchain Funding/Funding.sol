// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title Funding
 * @author Governaut
 * @notice This contract facilitates crowdfunding for various projects by accepting ERC20 tokens as contributions.
 * It allows an owner to create projects, contributors to donate, and the owner to withdraw funds once a project reaches
 * its goal.
 */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Funding is Ownable {
    IERC20 public token; // ERC20 token used for contributions

    struct Project {
        address projectOwner; // Owner of the project
        uint256 startTimestamp; // Start timestamp of the funding period
        uint256 endTimestamp; // End timestamp of the funding period
        uint256 goalAmount; // Goal amount to be raised
        mapping(address => uint256) contributions; // Mapping to store contributions
        uint256 totalContributed; // Total amount contributed so far
        bool isActive; // Whether the funding is active
    }

    /// @dev Mapping to store project details to projectOwner address
    mapping(address => Project) public projects;

    constructor(address initialOwner, IERC20 _token) Ownable(initialOwner) {
        token = _token;
    }
}
