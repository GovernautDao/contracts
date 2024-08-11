// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {WorldIDIdentityManagerRouterMock} from "../test/Anvil/Unit/mocks/WorldIDIdentityManagerRouterMock.sol";

contract HelperConfig is Script {
  string appId = "app_staging_6c8d4488699bc14d8d580282ac02b9d5";
  string actionId = "testing-verfication-action";
  address GOVERNANCE_TOKEN = address(0);

  struct Config {
    string _appid;
    string _actionId;
    address _WorldcoinRouterAddress;
    address _governanceToken;
  }

  // function getOpMainnetConfig() public view returns (Config memory) {
  //     Config memory OpMainnetConfig = Config({
  //         _appid: appId,
  //         _actionId: actionId,
  //         _WorldcoinRouterAddress: vm.envAddress("WORLDCOIN_ROUTERADDRESS_OP_MAINNET")
  //     });
  //     return OpMainnetConfig;
  // }

  // function getMetalL2TestnetConfig() public view returns (Config memory) {
  //     Config memory MetalL2Config = Config({
  //         _appid: appId,
  //         _actionId: actionId,
  //         _WorldcoinRouterAddress: vm.envAddress("WORLDCOIN_ROUTERADDRESS_OP_SEPOLIA")
  //     });
  //     return MetalL2Config;
  // }
  function getOpMainnetConfig() public view returns (Config memory) {
    Config memory OpMainnetConfig = Config({
      _appid: appId,
      _actionId: actionId,
      _WorldcoinRouterAddress: vm.envAddress(
        "WORLDCOIN_ROUTERADDRESS_OP_MAINNET"
      ),
      _governanceToken: GOVERNANCE_TOKEN
    });
    return OpMainnetConfig;
  }

  function getOpSepoliaConfig() public view returns (Config memory) {
    Config memory OpSepoliaConfig = Config({
      _appid: appId,
      _actionId: actionId,
      _WorldcoinRouterAddress: 0x11cA3127182f7583EfC416a8771BD4d11Fae4334,
      _governanceToken: GOVERNANCE_TOKEN
    });
    return OpSepoliaConfig;
  }

  // function getEthMainnetConfig() public view returns (Config memory) {
  //     Config memory EthMainnetConfig = Config({
  //         _appid: appId,
  //         _actionId: actionId,
  //         _WorldcoinRouterAddress: vm.envAddress("WORLDCOIN_ROUTERADDRESS_ETH_MAINNET")
  //     });
  //     return EthMainnetConfig;
  // }

  // function getEthSepoliaConfig() public view returns (Config memory) {
  //     Config memory EthSepoliaConfig = Config({
  //         _appid: appId,
  //         _actionId: actionId,
  //         _WorldcoinRouterAddress: vm.envAddress("WORLDCOIN_ROUTERADDRESS_ETH_SEPOLIA")
  //     });
  //     return EthSepoliaConfig;
  // }

  function getBaseSepoliaConfig() public view returns (Config memory) {
    Config memory BaseSepoliaConfig = Config({
      _appid: appId,
      _actionId: actionId,
      _WorldcoinRouterAddress: 0x42FF98C4E85212a5D31358ACbFe76a621b50fC02,
      _governanceToken: GOVERNANCE_TOKEN
    });
    return BaseSepoliaConfig;
  }

  function getAnvilConfig() public returns (Config memory) {
    console.log("testing on anvil");
    WorldIDIdentityManagerRouterMock routerMock = new WorldIDIdentityManagerRouterMock();
    Config memory AnvilConfig = Config({
      _appid: appId,
      _actionId: actionId,
      _WorldcoinRouterAddress: address(routerMock),
      _governanceToken: GOVERNANCE_TOKEN
    });
    return AnvilConfig;
  }
}
