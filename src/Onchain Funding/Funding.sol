// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title Funding
 * @author Governaut
 * @dev Implements a crowdfunding mechanism, integrated with a governance contract for proposal validation. It supports
 * project grant creation, contributions in ERC20 tokens, and conditional fund withdrawal.
 * @notice This contract enables crowdfunding for projects through ERC20 token contributions. It allows for the creation
 * of project grants by approved proposers, contributions by supporters, and conditional withdrawal of funds by project
 * owners based on funding goals and timelines.
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
    error UserIsntAnApprovedProposer();
    error GovernautGovernanceCantBeAddressZero();
    error GrantHasEnded();
    error GrantGoalIsMet();
    error NoContributions();
    error OnlyProjectOwnerCanClaim();
    error GrantHasNotEnded();
    error GrantGoalNotMet();
    error NotEnoughTimePassed();
    error AllClaimsClaimed();

    /// @dev Represents a grant for project funding
    struct FundingGrant {
        address projectOwner; // Owner of the project
        uint256 startTimestamp; // Start timestamp of the funding period
        uint256 endTimestamp; // End timestamp of the funding period
        uint256 goalAmount; // Goal amount to be raised
        uint256 totalContributed; // Total amount contributed so far
        uint256 lastClaimTimestamp; // track the last claim timestamp
        uint8 numberOfClaimsMade; // track the number of claims made
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
        if (!governautGovernance.approvedProposers(msg.sender)) {
            revert UserIsntAnApprovedProposer();
        }
        _;
    }
    /**
     * @dev Constructor to initialize the Funding contract with governance and token addresses.
     * @param initialOwner Address of the initial owner of the contract.
     * @param _governautGovernanceAddress Address of the GovernautGovernance contract.
     * @param _token Address of the ERC20 token to be used for contributions.
     */

    constructor(address initialOwner, address _governautGovernanceAddress, IERC20 _token) Ownable(initialOwner) {
        if (_governautGovernanceAddress == address(0)) {
            revert GovernautGovernanceCantBeAddressZero();
        }
        governautGovernance = IGovernautGovernance(_governautGovernanceAddress);
        token = _token;
    }

    /**
     * @dev Creates a new grant with the specified details. Only callable by approved proposers.
     * @param projectOwner Address of the project owner.
     * @param goalAmount The funding goal amount for the project.
     * @notice This function initializes a new grant with a unique ID, registers it, and emits a GrantCreated event.
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
            lastClaimTimestamp: 0,
            numberOfClaimsMade: 0
        });

        emit GrantCreated(grantIdCounter, projectOwner, goalAmount, startTimestamp, endTimestamp);
        grantIdCounter++;
    }

    /**
     * @dev Allows users to contribute to a grant with the specified ID and amount.
     * @param grantId The ID of the grant to contribute to.
     * @param amount The amount of tokens to contribute.
     * @notice Contributions are only accepted if the grant is active. This function updates the grant's total
     * contributions and records the contributor's amount, then emits a ContributionMade event.
     */
    function contribute(uint256 grantId, uint256 amount) external {
        FundingGrant storage grant = grants[grantId];
        if (block.timestamp >= grant.endTimestamp) {
            revert GrantHasEnded();
        }
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        grant.totalContributed += amount;
        contributionsByUser[grantId][msg.sender] += amount;

        emit ContributionMade(msg.sender, grantId, amount);
    }

    /**
     * @dev Allows contributors to claim a refund if the grant's goal is not met by the end of the funding period.
     * @param grantId The ID of the grant to claim a refund from.
     * @notice Refunds are only possible if the grant has ended without meeting its goal. This function resets the
     * contributor's contribution to zero, transfers the contributed tokens back, and emits a Refunded event.
     */
    function claimContributionRefund(uint256 grantId) external nonReentrant {
        FundingGrant storage grant = grants[grantId];
        if (block.timestamp < grant.endTimestamp) {
            revert GrantHasNotEnded();
        }
        if (grant.totalContributed >= grant.goalAmount) {
            revert GrantGoalIsMet();
        }

        uint256 contributedAmount = contributionsByUser[grantId][msg.sender];
        if (contributedAmount == 0) {
            revert NoContributions();
        }
        contributionsByUser[grantId][msg.sender] = 0;
        require(token.transfer(msg.sender, contributedAmount), "Refund failed");

        emit Refunded(msg.sender, grantId, contributedAmount);
    }

    /**
     * @dev Allows the project owner to claim the funds raised if the grant's goal is met.
     * @param grantId The ID of the grant whose funds are to be claimed.
     * @notice The project owner can claim funds in increments after the grant ends and the goal is met. Claims are
     * limited to a maximum number and frequency. This function updates the last claim timestamp, increments the number
     * of claims made, transfers the claim amount to the project owner, and emits a FundsClaimed event.
     */
    function claimFunds(uint256 grantId) external nonReentrant {
        FundingGrant storage grant = grants[grantId];
        uint256 timeSinceLastClaim =
            block.timestamp - (grant.lastClaimTimestamp > 0 ? grant.lastClaimTimestamp : grant.endTimestamp);
        if (msg.sender != grant.projectOwner) {
            revert OnlyProjectOwnerCanClaim();
        }
        if (block.timestamp < grant.endTimestamp) {
            revert GrantHasNotEnded();
        }
        if (grant.totalContributed < grant.goalAmount) {
            revert GrantGoalNotMet();
        }
        if (grant.numberOfClaimsMade >= 4) {
            revert AllClaimsClaimed();
        }
        if (timeSinceLastClaim < 30 days) {
            revert NotEnoughTimePassed();
        }
        uint256 amountToClaim = grant.totalContributed / 4;
        grant.lastClaimTimestamp = block.timestamp;
        grant.numberOfClaimsMade += 1;

        require(token.transfer(msg.sender, amountToClaim), "Claim failed");

        emit FundsClaimed(grantId, msg.sender, amountToClaim);
    }

    /**
     * @dev Returns the status of a specific grant.
     * @param grantId The ID of the grant to query.
     * @return projectOwner The address of the project owner.
     * @return startTimestamp The start timestamp of the funding period.
     * @return endTimestamp The end timestamp of the funding period.
     * @return goalAmount The funding goal amount.
     * @return totalContributed The total amount contributed.
     * @return numberOfClaimsMade The number of claims made by the project owner.
     * @return lastClaimTimestamp The timestamp of the last claim made.
     * @notice This view function provides detailed information about a grant's status, including its progress towards
     * the funding goal and the claims made by the project owner.
     */
    function getGrantStatus(uint256 grantId)
        external
        view
        returns (
            address projectOwner,
            uint256 startTimestamp,
            uint256 endTimestamp,
            uint256 goalAmount,
            uint256 totalContributed,
            uint256 numberOfClaimsMade,
            uint256 lastClaimTimestamp
        )
    {
        FundingGrant storage grant = grants[grantId];
        return (
            grant.projectOwner,
            grant.startTimestamp,
            grant.endTimestamp,
            grant.goalAmount,
            grant.totalContributed,
            grant.numberOfClaimsMade,
            grant.lastClaimTimestamp
        );
    }
}
