// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title Funding
 * @author Governaut
 * @dev A crowdfunding contract that allows for the creation of project grants, contributions to those grants using
 * ERC20 tokens, and the withdrawal of funds by project owners upon successful funding. It integrates with a governance
 * contract to restrict grant creation to approved proposers.
 * @notice This contract facilitates crowdfunding for various projects by accepting ERC20 tokens as contributions. It
 * allows an owner to create projects, contributors to donate, and the owner to withdraw funds once a project reaches
 * its goal.
 */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGovernautGovernance } from "../Onchain Funding/interfaces/IGovernautGovernance.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Funding is Ownable, ReentrancyGuard {
    IGovernautGovernance governautGovernance; // Governance contract to check for approved proposers
    IERC20 token; // ERC20 token used for contributions

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @dev Represents a grant for project funding
    struct FundingGrant {
        address projectOwner; // Owner of the project
        uint256 startTimestamp; // Start timestamp of the funding period
        uint256 endTimestamp; // End timestamp of the funding period
        uint256 goalAmount; // Goal amount to be raised
        uint256 totalContributed; // Total amount contributed so far
        bool isActive; // Whether the funding is active
    }

    /// @dev Counter to assign unique IDs to each grant
    uint256 private grantIdCounter = 0;

    /// @dev Mapping from grant ID to FundingGrant struct
    mapping(uint256 => FundingGrant) private grants;

    /// @dev Mapping from grant ID to user address to contribution amount
    mapping(uint256 => mapping(address => uint256)) private contributionsByUser;

    /// @dev Event emitted when a new grant is created
    event GrantCreated(
        uint256 indexed grantId,
        address indexed projectOwner,
        uint256 indexed goalAmount,
        uint256 startTimestamp,
        uint256 endTimestamp
    );
    /// @dev Event emitted when a new contribution is made
    event ContributionMade(address indexed contributor, uint256 indexed grantId, uint256 indexed amount);
    /// @dev Event emitted when a grant is refunded
    event Refunded(address indexed contributor, uint256 indexed grantId, uint256 indexed amount);
    /// @dev Event emitted when funds are claimed by a project owner
    event FundsClaimed(uint256 indexed grantId, address indexed projectOwner, uint256 indexed amount);

    /// @dev Modifier to check if the caller is an approved proposer
    modifier onlyApprovedProposer() {
        require(governautGovernance.approvedProposers(msg.sender), "Caller is not an approved proposer");
        _;
    }

    /**
     * @dev Constructor to initialize the Funding contract with governance and token addresses.
     * @param initialOwner Address of the initial owner of the contract.
     * @param _governautGovernanceAddress Address of the GovernautGovernance contract.
     * @param _token Address of the ERC20 token to be used for contributions.
     */
    constructor(address initialOwner, address _governautGovernanceAddress, IERC20 _token) Ownable(initialOwner) {
        require(_governautGovernanceAddress != address(0), "GovernautGovernance address cannot be 0");
        governautGovernance = IGovernautGovernance(_governautGovernanceAddress);
        token = _token;
    }

    /**
     * @dev Creates a new grant with the specified details. Only callable by approved proposers.
     * @param projectOwner Address of the project owner.
     * @param goalAmount The funding goal amount for the project.
     */
    function createGrant(address projectOwner, uint256 goalAmount) external onlyApprovedProposer {
        uint256 startTimestamp = block.timestamp;
        uint256 endTimestamp = startTimestamp + 21 days;

        grants[grantIdCounter] = FundingGrant({
            projectOwner: projectOwner,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            goalAmount: goalAmount,
            totalContributed: 0,
            isActive: true
        });

        emit GrantCreated(grantIdCounter, projectOwner, goalAmount, startTimestamp, endTimestamp);
        grantIdCounter++;
    }

    /**
     * @dev Allows users to contribute to a grant with the specified ID and amount.
     * @param grantId The ID of the grant to contribute to.
     * @param amount The amount of tokens to contribute.
     */
    function contribute(uint256 grantId, uint256 amount) external {
        FundingGrant storage grant = grants[grantId];

        require(grant.isActive, "Grant is not active");
        require(block.timestamp < grant.endTimestamp, "Grant has ended");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        grant.totalContributed += amount;
        contributionsByUser[grantId][msg.sender] += amount;

        emit ContributionMade(msg.sender, grantId, amount);
    }

    /**
     * @dev Allows contributors to claim a refund if the grant's goal is not met by the end of the funding period.
     * @param grantId The ID of the grant to claim a refund from.
     */
    function claimRefund(uint256 grantId) external nonReentrant {
        FundingGrant storage grant = grants[grantId];

        require(block.timestamp > grant.endTimestamp, "Grant has not ended");
        require(grant.totalContributed < grant.goalAmount, "Grant goal not met");

        uint256 contributedAmount = contributionsByUser[grantId][msg.sender];
        require(contributedAmount > 0, "No contributions to refund");

        contributionsByUser[grantId][msg.sender] = 0;
        require(token.transfer(msg.sender, contributedAmount), "Refund failed");

        emit Refunded(msg.sender, grantId, contributedAmount);
    }

    /**
     * @dev Allows the project owner to claim the funds raised if the grant's goal is met.
     * @param grantId The ID of the grant whose funds are to be claimed.
     */
    function claimFunds(uint256 grantId) external nonReentrant {
        FundingGrant storage grant = grants[grantId];

        require(msg.sender == grant.projectOwner, "Only project owner can claim");
        require(block.timestamp > grant.endTimestamp, "Grant has not ended");
        require(grant.totalContributed >= grant.goalAmount, "Grant goal not met");

        uint256 amountToClaim = grant.totalContributed;
        grant.isActive = false; // Prevent further actions on this grant

        require(token.transfer(msg.sender, amountToClaim), "Claim failed");

        emit FundsClaimed(grantId, msg.sender, amountToClaim);
    }

    function getGrantStatus(uint256 grantId)
        external
        view
        returns (
            address projectOwner,
            uint256 startTimestamp,
            uint256 endTimestamp,
            uint256 goalAmount,
            uint256 totalContributed,
            bool isActive
        )
    {
        FundingGrant storage grant = grants[grantId];
        return (
            grant.projectOwner,
            grant.startTimestamp,
            grant.endTimestamp,
            grant.goalAmount,
            grant.totalContributed,
            grant.isActive
        );
    }
}
