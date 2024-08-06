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
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGovernautGovernance } from "../Onchain Funding/interfaces/IGovernautGovernance.sol";

contract Funding is Ownable {
    IGovernautGovernance governautGovernance;
    IERC20 token; // ERC20 token used for contributions

    struct FundingGrant {
        address projectOwner; // Owner of the project
        uint256 startTimestamp; // Start timestamp of the funding period
        uint256 endTimestamp; // End timestamp of the funding period
        uint256 goalAmount; // Goal amount to be raised
        uint256 totalContributed; // Total amount contributed so far
        bool isActive; // Whether the funding is active
    }

    /// @dev Initializes the Funding contract with the given parameters.
    uint256 private grantIdCounter = 0;

    /// @dev Mapping to store project details
    mapping(uint256 => FundingGrant) private grants;

    /// @dev Mapping to store contributions to projectOwner address
    mapping(address => mapping(address => uint256)) private projectContributions;

    constructor(address initialOwner, address _governautGovernanceAddress, IERC20 _token) Ownable(initialOwner) {
        require(_governautGovernanceAddress != address(0), "GovernautGovernance address cannot be 0");
        governautGovernance = IGovernautGovernance(_governautGovernanceAddress);
        token = _token;
    }
}
