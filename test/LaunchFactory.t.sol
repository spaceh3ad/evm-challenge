// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {LaunchFactory} from "../src/LaunchFactory.sol";
import {Curation} from "../src/Curation.sol";
import {CurationV2} from "../src/CurationV2.sol";
import "../src/lib/Structs.sol";
import "../src/lib/Events.sol";

import "@openzeppelin/foundry-upgrades/src/Upgrades.sol";

contract LaunchFactoryTest is Test {
    LaunchFactory launchFactory;
    Curation curation;

    MockERC20 curationToken;
    MockERC20 newToken;

    address baseSepoliapositionManager =
        0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;

    address deployer;

    function setUp() public {
        string memory rpcAlias = "base_sepolia";
        string memory rpcUrl = getChain(rpcAlias).rpcUrl;
        vm.createSelectFork(rpcUrl);

        deployer = makeAddr("deployer");

        curationToken = new MockERC20();
        curationToken.initialize("Curation Token", "CURT", 18);

        newToken = new MockERC20();
        newToken.initialize("New Token", "NEWT", 18);

        curation = new Curation();
        launchFactory = LaunchFactory(deployFactory(address(curationToken)));

        deal(address(curationToken), deployer, 1_000_000 ether);
        vm.prank(deployer);
        curationToken.approve(address(launchFactory), 1_000_000 ether);
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

    function test_createSubmision() public {
        vm.expectEmit(false, false, false, false, address(launchFactory));
        emit SubmissionCreated(address(curation));

        vm.prank(deployer);
        launchFactory.createSubmission(getCurationDetails());
    }

    function test_upgradeImplemntation() public {
        address newCurationImplementation = address(new CurationV2());

        vm.expectEmit(true, false, false, false, address(launchFactory));
        emit ImplementationUpgraded(newCurationImplementation);

        launchFactory.upgradeImplementation(newCurationImplementation);
        assertEq(
            launchFactory.curationImplementation(),
            newCurationImplementation
        );
    }

    function test_newFeatureInCurationV2() public {
        // resue test case to upgrade implementation
        test_upgradeImplemntation();

        vm.prank(deployer);
        address curationIntance = launchFactory.createSubmission(
            getCurationDetails()
        );

        CurationV2(curationIntance).setV2();
        assertEq(CurationV2(curationIntance).isV2(), true);
    }

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
            liquidityAmount: 300_000 ether
        });
    }
}
