// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { Script } from "forge-std/Script.sol";
import { IVotes } from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import { GovernautGovernance } from "../src/Governance Tools/GovernautGovernance.sol";
import { IdentityManager } from "../src/Identity Management/IdentityManager.sol";
import { Funding } from "../src/Onchain Funding/Funding.sol";
import { GovernanceToken } from "../src/Governance Tools/GovernanceToken.sol";

contract DeployContracts is Script {
    HelperConfig helperConfig;
    IdentityManager identitymanager;
    Funding funding;
    GovernautGovernance governance;
    GovernanceToken governanceToken;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        helperConfig = new HelperConfig();
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying GovernanceToken...");
        governanceToken = new GovernanceToken(deployer, 1_000_000_000 * 10 ** 18); // 1 billion tokens with 18 decimals
        console.log("GovernanceToken deployed at:", address(governanceToken));

        console.log("Deploying IdentityManager...");
        identitymanager = new IdentityManager(
            vm.addr(deployerPrivateKey),
            helperConfig.getMetalL2TestnetConfig()._WorldcoinRouterAddress,
            helperConfig.getMetalL2TestnetConfig()._appid,
            helperConfig.getMetalL2TestnetConfig()._actionId
        );
        console.log("IdentityManager deployed at:", address(identitymanager));

        console.log("Deploying GovernautGovernance implementation...");
        GovernautGovernance implementation = new GovernautGovernance();
        console.log("GovernautGovernance implementation deployed at:", address(implementation));

        console.log("Deploying ProxyAdmin...");
        ProxyAdmin proxyAdmin = new ProxyAdmin(address(this));
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));

        console.log("Preparing initialization data for GovernautGovernance...");
        bytes memory initData = abi.encodeWithSelector(
            GovernautGovernance.initialize.selector, IVotes(address(governanceToken)), address(identitymanager)
        );

        console.log("Deploying TransparentUpgradeableProxy for GovernautGovernance...");
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(implementation), address(proxyAdmin), initData);
        console.log("TransparentUpgradeableProxy deployed at:", address(proxy));

        governance = GovernautGovernance(payable(address(proxy)));
        console.log("GovernautGovernance (via proxy) available at:", address(governance));

        console.log("Deploying Funding contract...");
        funding = new Funding(deployer, address(governance), address(governanceToken));
        console.log("Funding contract deployed at:", address(funding));

        vm.stopBroadcast();

        console.log("\nDeployment Summary:");
        console.log("-------------------");
        console.log("GovernanceToken: ", address(governanceToken));
        console.log("IdentityManager: ", address(identitymanager));
        console.log("GovernautGovernance (implementation): ", address(implementation));
        console.log("ProxyAdmin: ", address(proxyAdmin));
        console.log("GovernautGovernance (proxy): ", address(governance));
        console.log("Funding: ", address(funding));
    }
}
