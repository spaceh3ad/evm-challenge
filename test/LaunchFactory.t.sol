// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";

import {LaunchFactory} from "../src/LaunchFactory.sol";
import {Curation} from "../src/Curation.sol";
import "../src/lib/Structs.sol";
import "../src/lib/Events.sol";

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
        launchFactory = new LaunchFactory(
            address(curation),
            baseSepoliapositionManager
        );
    }

    function test_createSubmision() public {
        deal(address(curationToken), deployer, 1_000_000 ether);

        CurationDetails memory curationDetails = CurationDetails({
            curationToken: IERC20(address(curationToken)),
            newToken: IERC20(address(newToken)),
            distributionAmount: 1_000_000 ether,
            targetAmount: 200_000 ether
        });

        vm.startPrank(deployer);
        curationToken.approve(address(launchFactory), 1_000_000 ether);

        vm.expectEmit(false, false, false, false, address(launchFactory));
        emit SubmissionCreated(address(curation));

        launchFactory.createSubmission(curationDetails);
        vm.stopPrank();
    }
}
