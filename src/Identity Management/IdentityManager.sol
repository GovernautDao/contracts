// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IdentityManager
 * @author Governaut
 * @notice Contract will handle identity verification using World ID on #Superchain.
 * It will store mappings of user addresses to unique identifiers provided by World ID, ensuring privacy and security.
 */
import { ByteHasher } from "./helpers/ByteHasher.sol";
import { IWorldID } from "./interfaces/IWorldID.sol";

contract IdentityManager {
    using ByteHasher for bytes;

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when attempting to reuse a nullifier
    error DuplicateNullifier(uint256 nullifierHash);

    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The contract's external nullifier hash
    uint256 internal immutable externalNullifier;

    /// @dev The World ID group ID (always 1)
    uint256 internal immutable groupId = 1;

    /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a
    /// single person
    mapping(uint256 => bool) internal nullifierHashes;

    /// @dev Mapping from a user's address to whether the user has verified or not
    mapping(address => bool) internal userMapping;

    /// @param nullifierHash The nullifier hash for the verified proof
    /// @dev A placeholder event that is emitted when a user successfully verifies with World ID
    event Verified(uint256 nullifierHash);

    /// @param _worldId The WorldID router that will verify the proofs
    /// @param _appId The World ID app ID
    /// @param _actionId The World ID action ID
    constructor(address _worldId, string memory _appId, string memory _actionId) {
        worldId = IWorldID(_worldId);
        externalNullifier = abi.encodePacked(abi.encodePacked(_appId).hashToField(), _actionId).hashToField();
    }

    /// @param signal An arbitrary input from the user, usually the user's wallet address (check README for further
    /// details)
    /// @param root The root of the Merkle tree (returned by the JS widget).
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
    /// @param proof The zero-knowledge proof that demonstrates the claimer is registered with World ID (returned by the
    /// JS widget).
    /// @dev Feel free to rename this method however you want! We've used `claim`, `verify` or `execute` in the past.
    function verifyAndExecute(address signal, uint256 root, uint256 nullifierHash, uint256[8] calldata proof) public {
        // First, we make sure this person hasn't done this before
        if (nullifierHashes[nullifierHash]) {
            revert DuplicateNullifier(nullifierHash);
        }

        // We now verify the provided proof is valid and the user is verified by World ID
        worldId.verifyProof(
            root, groupId, abi.encodePacked(signal).hashToField(), nullifierHash, externalNullifier, proof
        );

        // We now record the user has done this, so they can't do it again (proof of uniqueness)
        nullifierHashes[nullifierHash] = true;

        // Finally, execute your logic here, for example issue a token, NFT, etc...
        // Make sure to emit some kind of event afterwards!

        emit Verified(nullifierHash);
        userMapping[msg.sender] = true;
    }

    /**
     * @notice returns bool indicating if a user is verified using orb level verification on worldcoin
     * @dev currently public
     * @param _user address of the queried user
     * @return bool
     */
    function getIsVerified(address _user) public view returns (bool) {
        return userMapping[_user];
    }

    function dumbVerify() public {
        userMapping[msg.sender] = true;
    }
}
