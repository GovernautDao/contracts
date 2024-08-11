# Governaut Contracts Repository

## Overview

Governaut is a decentralized identity and governance dashboard that integrates decentralized identity verification, governance tools, and attestation systems. This repository contains the smart contracts that form the backbone of the Governaut platform, facilitating governance interactions, identity verification, and community project funding through integration with Celo's onchain mechanisms.

## Table of Contents

- [Governaut Contracts Repository](#governaut-contracts-repository)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
  - [Contracts Overview](#contracts-overview)
    - [Contract 1: GovernanceContract](#contract-1-governancecontract)
      - [Description](#description)
    - [Key Features](#key-features)
    - [Functions Overview](#functions-overview)
      - [Constructor](#constructor)
      - [Propose](#propose)
      - [Execute](#execute)
      - [CastVote](#castvote)
      - [IsApprovedProposer](#isapprovedproposer)
    - [Security Considerations](#security-considerations)
    - [Recap](#recap)
  - [License](#license)

## Getting Started

To get a copy of the project up and running on your local machine for development and testing purposes, follow these steps.

### Prerequisites

Ensure you have the following prerequisites installed:

- Solidity compiler (solc 0.8.24)
- Foundry for development and testing
- Anvil or another local blockchain for testing

### Installation

Clone the repository to your local machine:

`git clone https://github.com/GovernautDao/contracts.git`

Install dependencies:

`forge install`

Compile the contracts:

`forge build`


## Contracts Overview

### Contract 1: GovernanceContract

#### Description

The `GovernautGovernance` contract is a sophisticated governance system designed for managing grant-related proposals within the Governaut ecosystem. Leveraging OpenZeppelin's governance contracts, it extends various functionalities to integrate seamlessly with an Identity Manager, ensuring that only verified identities can participate in governance actions. This contract plays a pivotal role in democratizing decision-making processes by allowing token holders to propose, vote on, and execute proposals.

### Key Features

- Identity Verification: Utilizes an external Identity Manager to verify the identity of participants, ensuring that only verified users can create proposals and cast votes.
- Proposal Creation and Voting: Allows verified users to submit proposals for community consideration and enables voting on these proposals using a simple majority counting mechanism.
- Quorum Requirements: Implements quorum requirements to ensure a minimum level of voter participation for proposal execution.
- Approved Proposers Tracking: Maintains a record of approved proposers, marking them once their proposal has been successfully executed.

### Functions Overview

#### Constructor

```
constructor(
    IVotes _token,
    address _identityManagerAddress
)
```

Initializes the contract with the ERC20 token used for voting and the address of the Identity Manager contract.

#### Propose

```
function propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description
)
    public
    override(Governor)
    onlyVerifiedIdentity
    returns (uint256)
```

Allows a verified user to create a new governance proposal specifying target contracts, call values, call data, and a description.

#### Execute

```
function execute(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
)
    public
    payable
    virtual
    override(Governor)
    returns (uint256)
```

Executes a successful proposal after the voting period ends, provided it meets the quorum and passes the vote.

#### CastVote

```
function castVote(
    uint256 proposalId,
    uint8 support
)
    public
    virtual
    override(Governor)
    onlyVerifiedIdentity
    returns (uint256)
```

Enables a verified user to cast a vote on a proposal, supporting, opposing, or abstaining.

#### IsApprovedProposer

```
function isApprovedProposer(address proposer) public view returns (bool)
```

Checks if an address has been marked as an approved proposer after successfully executing a proposal.

### Contract 2: Identity Manager

#### Description

The `Identity Manager` contract is a contract that integrates with worldcoin to verify proofs on chain. Only Orb level verification is supported. Users do not directly call this contract but the governance contract calls this contract to verify that a user is authenticated or not.

### Key Features

- Identity Verification: Utilizes a Identity Manager to verify the identity of participants, ensuring that only verified users can create proposals and cast votes.
- Bridges for interacting with identity manager are added for  Mode testnet and Metal l2 and are verified using blockscout

### Functions Overview
veriifyProof() verifies the user onchain.

### Contract 3: Funding

#### Description

This funding contract is designed to facilitate the creation and management of grants within a decentralized governance framework. It operates in conjunction with the Governaut governance contracts, ensuring that grants are only created if the user has received sufficient approval votes.



### Key Features

Grant Creation:
Project owners can create grants to seek funding for their projects. These grants are subject to approval by the Governaut governance system, ensuring community oversight.
Goal-Driven Funding:
Each grant has a specific funding goal. Once this goal is met, the project owner can withdraw the funds to execute their project.
Refund Mechanism:
If a grant does not reach its funding goal within a specified period, contributors can claim a refund of their contributions, ensuring that funds are only used for successful projects.


### Security Considerations

- Identity Verification: Ensures that only approved users can participate in creating grants, mitigating risks associated with anonymous participation.
- Access Control: Utilizes modifiers to restrict certain functions to approved identities, enhancing security and integrity of the funding process.

### Recap

The Funding contract represents a robust framework for creating crowd funding grants and managing assets.
## License

Distributed under the MIT License.
