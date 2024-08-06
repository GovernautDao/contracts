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
        bool goalReached; // Whether the goal amount was reached
    }

    /// @dev Initializes the Funding contract with the given parameters.
    uint256 private grantIdCounter = 0;

    /// @dev Mapping to store project details
    mapping(uint256 => FundingGrant) private grants;

    /// @dev Mapping to store contributions by user for each grant
    mapping(uint256 => mapping(address => uint256)) private contributionsByUser;

    event GrantCreated(
        uint256 indexed grantId,
        address indexed projectOwner,
        uint256 indexed goalAmount,
        uint256 startTimestamp,
        uint256 endTimestamp
    );
    event ContributionMade(address indexed contributor, uint256 indexed grantId, uint256 indexed amount);

    modifier onlyApprovedProposer() {
        require(governautGovernance.approvedProposers(msg.sender), "Caller is not an approved proposer");
        _;
    }

    constructor(address initialOwner, address _governautGovernanceAddress, IERC20 _token) Ownable(initialOwner) {
        require(_governautGovernanceAddress != address(0), "GovernautGovernance address cannot be 0");
        governautGovernance = IGovernautGovernance(_governautGovernanceAddress);
        token = _token;
    }

    function createGrant(address projectOwner, uint256 goalAmount) external onlyApprovedProposer {
        uint256 startTimestamp = block.timestamp;
        uint256 endTimestamp = startTimestamp + 21 days;

        grants[grantIdCounter] = FundingGrant({
            projectOwner: projectOwner,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            goalAmount: goalAmount,
            totalContributed: 0,
            isActive: true,
            goalReached: false
        });

        emit GrantCreated(grantIdCounter, projectOwner, goalAmount, startTimestamp, endTimestamp);
        grantIdCounter++;
    }

    function contribute(uint256 grantId, uint256 amount) external {
        require(grants[grantId].isActive, "Grant is not active");
        require(block.timestamp < grants[grantId].endTimestamp, "Grant has ended");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        grants[grantId].totalContributed += amount;
        contributionsByUser[grantId][msg.sender] += amount;

        emit ContributionMade(msg.sender, grantId, amount);
    }
}
