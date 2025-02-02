// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "@openzeppelin/foundry-upgrades/src/Upgrades.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Token} from "../src/mock/Token.sol";
import {LaunchFactory, CurationDetails} from "../src/launchFactory/v1/LaunchFactory.sol";

import {Curation} from "../src/curation/v1/Curation.sol";
import {CurationV2} from "../src/curation/v2/CurationV2.sol";

contract FactoryDeployScript is Script {
    uint256 deployerPrivateKey;
    address deployerAddress;

    address positionManager = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;

    address factory;
    Curation curation;

    Token curationToken;
    Token newToken;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployerAddress);
    }

    function run() public {
        vm.startBroadcast();
        deploy();
        deployToken();
        createSubmission();
        vm.stopBroadcast();
    }

    function deploy() public {
        curation = new Curation();

        factory = Upgrades.deployTransparentProxy(
            "LaunchFactory.sol",
            deployerAddress,
            abi.encodeCall(
                LaunchFactory.initialize,
                (deployerAddress, address(curation), positionManager)
            )
        );

        console.log("Curation deployed at: ", address(curation));
        console.log("LaunchFactory deployed at: ", factory);
    }

    function updateFactory() public {
        Upgrades.upgradeProxy(
            factory,
            "LaunchFactoryV2.sol",
            abi.encodeCall(
                LaunchFactory.initialize,
                (deployerAddress, address(curation), positionManager)
            )
        );
    }

    function updateCurationImplementation() public {
        CurationV2 curationImplV2 = new CurationV2();
        LaunchFactory(factory).upgradeImplementation(address(curationImplV2));
    }

    function deployToken() public {
        newToken = new Token("New Token", "NEWT");
        curationToken = new Token("Curation Token", "CURT");
    }

    function createSubmission() public {
        uint256 distributionAmount = 100_000 ether;
        uint256 targetAmount = 250_000 ether;
        uint256 liquidityAmount = 50_000 ether;

        newToken.approve(factory, distributionAmount + liquidityAmount);

        CurationDetails memory _curationDetails = CurationDetails({
            curationToken: IERC20(address(curationToken)),
            newToken: IERC20(address(newToken)),
            distributionAmount: distributionAmount,
            targetAmount: targetAmount,
            liquidityAmount: liquidityAmount,
            creator: deployerAddress
        });

        LaunchFactory(factory).createSubmission(_curationDetails);
    }
}
