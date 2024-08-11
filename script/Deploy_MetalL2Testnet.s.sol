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
      .getOpSepoliaConfig()
      ._governanceToken;
    console.log(governancetoken);
    vm.startBroadcast(deployerPrivateKey);

    identitymanager = new IdentityManager(
      helperConfig.getOpSepoliaConfig()._WorldcoinRouterAddress,
      helperConfig.getOpSepoliaConfig()._appid,
      helperConfig.getOpSepoliaConfig()._actionId
    );

    console.log("Identity Manager Address :", address(identitymanager));

    governance = new GovernautGovernance(
      IVotes(governancetoken),
      address(identitymanager)
    );

    console.log("Governaut Governance Address :", address(governance));

    funding = new Funding(
      vm.addr(deployerPrivateKey),
      address(governance),
      governancetoken
    );

    console.log("Funding Address :", address(funding));

    vm.stopBroadcast();
  }
}
