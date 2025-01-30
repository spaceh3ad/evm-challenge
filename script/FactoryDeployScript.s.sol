// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "@openzeppelin/foundry-upgrades/src/Upgrades.sol";

import {LaunchFactory} from "../src/launchFactory/v1/LaunchFactory.sol";

contract FactoryDeployScript is Script {
    uint256 deployerPrivateKey;
    address deployerAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployerAddress);
    }

    function run() public {
        vm.startBroadcast();

        vm.stopBroadcast();
    }

    function deploy() public {
        // address proxy = Upgrades.deployTransparentProxy(
        //     "TokenLauncherFactory.sol",
        //     deployerAddress,
        //     abi.encodeCall(TokenLauncherFactory.initialize, (deployerAddress))
        // );
    }
}
