// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";
import "../src/Governance Tools/GovernautGovernance.sol";
import "../src/Identity Management/IdentityManager.sol";
import "../src/Governance Tools/GovernanceToken.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Funding} from "../src/Onchain Funding//Funding.sol";

contract DeployContracts is Script {
  HelperConfig helperConfig;
  IdentityManager identityManager;
  GovernautGovernance governance;
  GovernanceToken governanceToken;
  Funding funding;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);
    helperConfig = new HelperConfig();

    console.log("Deploying contracts...");

    vm.startBroadcast(deployerPrivateKey);

    // Deploy GovernanceToken
    governanceToken = new GovernanceToken(deployer, 1_000_000 * 10 ** 18); // 1 million tokens with 18 decimals
    console.log("GovernanceToken deployed at:", address(governanceToken));

    // Deploy IdentityManager
    HelperConfig.Config memory config = helperConfig.getBaseSepoliaConfig(); // Or use the appropriate network
    // config
    identityManager = new IdentityManager(
      config._WorldcoinRouterAddress,
      config._appid,
      config._actionId
    );
    console.log("IdentityManager deployed at:", address(identityManager));

    // Deploy GovernautGovernance
    governance = new GovernautGovernance(
      IVotes(address(governanceToken)),
      address(identityManager)
    );
    console.log("GovernautGovernance deployed at:", address(governance));

    // Deploy Funding
    funding = new Funding(
      vm.addr(deployerPrivateKey),
      address(governance),
      address(governanceToken)
    );
    console.log("Funding deployed at:", address(funding));

    vm.stopBroadcast();

    console.log("All contracts deployed successfully.");
  }
}
