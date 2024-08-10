// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";
import "../src/Governance Tools/GovernautGovernance.sol";
import "../src/Identity Management/IdentityManager.sol";
import "../src/Onchain Funding/Funding.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract MyScript is Script {
  HelperConfig helperConfig;
  IdentityManager identitymanager;
  Funding funding;
  GovernautGovernance governance;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    helperConfig = new HelperConfig();
    address governancetoken = helperConfig
      .getMetalL2TestnetConfig()
      ._governanceTokenForThatChain;
    console.log(governancetoken);
    vm.startBroadcast(deployerPrivateKey);

    // Deploy the IdentityManager contract first
    identitymanager = new IdentityManager(
      vm.addr(deployerPrivateKey),
      helperConfig.getMetalL2TestnetConfig()._WorldcoinRouterAddress,
      helperConfig.getMetalL2TestnetConfig()._appid,
      helperConfig.getMetalL2TestnetConfig()._actionId
    );

    console.log("Identity Manager Address :", address(identitymanager));

    // Deploy the implementation contract
    GovernautGovernance implementation = new GovernautGovernance();

    // Deploy the ProxyAdmin
    ProxyAdmin proxyAdmin = new ProxyAdmin(
      0xfe63Ba8189215E5C975e73643b96066B6aD41A45
    );

    // Prepare initialization data for GovernautGovernance with the correct IdentityManager address
    bytes memory initData = abi.encodeWithSelector(
      GovernautGovernance.initialize.selector,
      IVotes(governancetoken),
      address(identitymanager)
    );

    // Deploy the TransparentUpgradeableProxy with the correct initialization data
    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
      address(implementation),
      address(proxyAdmin),
      initData
    );

    // Treat the proxy as the GovernautGovernance contract
    governance = GovernautGovernance(payable(address(proxy)));

    console.log("Governaut Governance Address :", address(governance));

    // Deploy the Funding contract
    funding = new Funding(
      vm.addr(deployerPrivateKey),
      address(governance),
      governancetoken
    );

    console.log("Funding Address :", address(funding));

    vm.stopBroadcast();
  }
}
