// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";
import "../src/Governance Tools/GovernautGovernance.sol";
import "../src/Identity Management/IdentityManager.sol";
import "../src/Onchain Funding/Funding.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
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
    identitymanager = new IdentityManager(
      vm.addr(deployerPrivateKey),
      helperConfig.getMetalL2TestnetConfig()._WorldcoinRouterAddress,
      helperConfig.getMetalL2TestnetConfig()._appid,
      helperConfig.getMetalL2TestnetConfig()._actionId
    );
    governance = new GovernautGovernance(
      IVotes(governancetoken),
      address(identitymanager)
    );
    funding = new Funding(
      vm.addr(deployerPrivateKey),
      address(governance),
      governancetoken
    );
    vm.stopBroadcast();
  }
}
