// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IdentityManager} from "./IdentityManager.sol";

/**
 * @title Governance
 * @author Governaut
 * @notice This contract will facilitate governance interactions, such as voting and proposal submissions, on Optimism (and #Superchain Networks).
 * It will integrate with the identity management contract to ensure only verified users can participate.
 */
contract Governance {
    IdentityManager idManager;

    constructor(address _identityManager) {
        idManager = IdentityManager(_identityManager);
    }
}
