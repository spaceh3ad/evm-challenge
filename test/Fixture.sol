// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import "@openzeppelin/foundry-upgrades/src/Upgrades.sol";

import {LaunchFactory} from "../src/launchFactory/v1/LaunchFactory.sol";
import {LaunchFactoryV2} from "../src/launchFactory/v2/LaunchFactoryV2.sol";
import {Curation} from "../src/curation/v1/Curation.sol";
import {CurationV2} from "../src/curation/v2/CurationV2.sol";
import "../src/lib/Structs.sol";
import "../src/lib/Events.sol";

contract Fixture is Test {
    LaunchFactory launchFactory;
    Curation curation;

    MockERC20 curationToken;
    MockERC20 newToken;

    address baseSepoliapositionManager =
        0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;

    address deployer;
    address bob;

    function setUp() public virtual {
        string memory rpcAlias = "base_sepolia";
        string memory rpcUrl = getChain(rpcAlias).rpcUrl;
        vm.createSelectFork(rpcUrl);

        deployer = makeAddr("deployer");
        bob = makeAddr("bob");

        curationToken = new MockERC20();
        curationToken.initialize("Curation Token", "CURT", 18);

        newToken = new MockERC20();
        newToken.initialize("New Token", "NEWT", 18);

        curation = new Curation();
        launchFactory = LaunchFactory(deployFactory(address(curation)));

        deal(address(newToken), deployer, 100_000_000 ether);

        vm.prank(deployer);
        newToken.approve(address(launchFactory), type(uint256).max);
    }

    function deployFactory(address _curation) public returns (address proxy) {
        proxy = Upgrades.deployTransparentProxy(
            "LaunchFactory.sol",
            deployer,
            abi.encodeCall(
                LaunchFactory.initialize,
                (deployer, _curation, baseSepoliapositionManager)
            )
        );
    }

    function upgradeFactory(
        address _proxy,
        string memory _newImplementationContractName,
        bytes memory _data
    ) public {
        Upgrades.upgradeProxy(
            _proxy,
            _newImplementationContractName,
            _data,
            deployer
        );
    }

    function createSubmission() public returns (address curationInstance) {
        vm.prank(deployer);
        return launchFactory.createSubmission(getCurationDetails());
    }

    /*//////////////////////////////////////////////////////////////
                                 UTILS
    //////////////////////////////////////////////////////////////*/
    function getCurationDetails()
        internal
        view
        returns (CurationDetails memory curationDetails)
    {
        curationDetails = CurationDetails({
            curationToken: IERC20(address(curationToken)),
            newToken: IERC20(address(newToken)),
            distributionAmount: 1_000_000 ether,
            targetAmount: 200_000 ether,
            liquidityAmount: 300_000 ether,
            creator: msg.sender
        });
    }
}
