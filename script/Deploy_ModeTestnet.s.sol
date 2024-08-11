// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @dev Demo deployments
import {Script} from "forge-std/Script.sol";
import {OpStateBridge} from "World Id Bridge/src/OpStateBridge.sol";
import {OpWorldID} from "World Id Bridge/src/OpWorldId.sol";
import {console} from "forge-std/console.sol";

/// @title Optimism State Bridge deployment script
/// @notice forge script to deploy StateBridge.sol on Optimism
/// @author Worldcoin
/// @dev Can be executed by running `make mock`, `make local-mock`, `make deploy` or `make deploy-testnet`.
contract DeployOpStateBridgeGoerli is Script {
  OpStateBridge public bridge;
  OpWorldID public opWorld;

  address public opWorldIDAddress;
  address public worldIDIdentityManagerAddress;
  address public opCrossDomainMessengerAddress;

  function setUp() public {
    ///////////////////////////////////////////////////////////////////
    ///                           OPTIMISM                          ///
    ///////////////////////////////////////////////////////////////////
    opCrossDomainMessengerAddress = address(
      0x5086d1eEF304eb5284A0f6720f79403b4e9bE294
    );

    ///////////////////////////////////////////////////////////////////
    ///                           WORLD ID                          ///
    ///////////////////////////////////////////////////////////////////
    worldIDIdentityManagerAddress = 0x11cA3127182f7583EfC416a8771BD4d11Fae4334;
  }

  function run() public {
    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
    opWorld = new OpWorldID(30);
    opWorldIDAddress = address(opWorld);

    bridge = new OpStateBridge(
      worldIDIdentityManagerAddress,
      opWorldIDAddress,
      opCrossDomainMessengerAddress
    );
    console.log("op world id address", address(opWorld));

    vm.stopBroadcast();
  }
}
