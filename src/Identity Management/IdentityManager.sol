// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IdentityManager
 * @author Governaut
 * @notice Contract will handle identity verification using World ID on #Superchain.
 * It will store mappings of user addresses to unique identifiers provided by World ID, ensuring privacy and security.
 */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract IdentityManager is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) { }
}
