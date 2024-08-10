// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {WorldIDIdentityManagerRouterMock} from "../test/Anvil/Unit/mocks/WorldIDIdentityManagerRouterMock.sol";

contract HelperConfig is Script {
  string appId = vm.envString("WORLDCOIN_APP_ID");
  string actionId = vm.envString("WORLDCOIN_ACTION_ID");

  struct Config {
    string _appid;
    string _actionId;
    address _WorldcoinRouterAddress;
    address _governanceTokenForThatChain;
  }

  function getOpMainnetConfig() public view returns (Config memory) {
    Config memory OpMainnetConfig = Config({
      _appid: appId,
      _actionId: actionId,
      _WorldcoinRouterAddress: vm.envAddress(
        "WORLDCOIN_ROUTERADDRESS_OP_MAINNET"
      ),
      _governanceTokenForThatChain: address(0)
    });
    return OpMainnetConfig;
  }

  function getMetalL2TestnetConfig() public view returns (Config memory) {
    Config memory MetalL2Config = Config({
      _appid: appId,
      _actionId: actionId,
      _WorldcoinRouterAddress: vm.envAddress(
        "WORLDCOIN_ROUTERADDRESS_OP_SEPOLIA"
      ),
      _governanceTokenForThatChain: vm.envAddress(
        "GOVERNENCE_TOKEN_METALL2_TESTNET"
      )
    });
    return MetalL2Config;
  }

  function getOpSepoliaConfig() public view returns (Config memory) {
    Config memory OpSepoliaConfig = Config({
      _appid: appId,
      _actionId: actionId,
      _WorldcoinRouterAddress: vm.envAddress(
        "WORLDCOIN_ROUTERADDRESS_OP_SEPOLIA"
      ),
      _governanceTokenForThatChain: vm.envAddress(
        "GOVERNENCE_TOKEN_METALL2_TESTNET"
      )
    });
    return OpSepoliaConfig;
  }

  function getEthMainnetConfig() public view returns (Config memory) {
    Config memory EthMainnetConfig = Config({
      _appid: appId,
      _actionId: actionId,
      _WorldcoinRouterAddress: vm.envAddress(
        "WORLDCOIN_ROUTERADDRESS_ETH_MAINNET"
      ),
      _governanceTokenForThatChain: address(0)
    });
    return EthMainnetConfig;
  }

  function getEthSepoliaConfig() public view returns (Config memory) {
    Config memory EthSepoliaConfig = Config({
      _appid: appId,
      _actionId: actionId,
      _WorldcoinRouterAddress: vm.envAddress(
        "WORLDCOIN_ROUTERADDRESS_ETH_SEPOLIA"
      ),
      _governanceTokenForThatChain: address(0)
    });
    return EthSepoliaConfig;
  }

  function getAnvilConfig() public returns (Config memory) {
    console.log("testing on anvil");
    WorldIDIdentityManagerRouterMock routerMock = new WorldIDIdentityManagerRouterMock();
    Config memory AnvilConfig = Config({
      _appid: appId,
      _actionId: actionId,
      _WorldcoinRouterAddress: address(routerMock),
      _governanceTokenForThatChain: address(0)
    });
    return AnvilConfig;
  }
}
