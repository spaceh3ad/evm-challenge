// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";

import {TokenLauncherFactory} from "../src/TokenLauncherFactory.sol";
import {Curation} from "../src/TokenLauncherFactory.sol";

contract TestFairlaunch is Test {
    TokenLauncherFactory tokenLauncherFactory;
    Curation curation;

    MockERC20 curationToken;
    MockERC20 newToken;

    address baseSepoliapositionManager =
        0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;

    address deployer;

    function setup() public {
        string memory rpcAlias = "base_sepolia";
        string memory rpcUrl = getChain(rpcAlias).rpcUrl;
        vm.createSelectFork(rpcUrl);

        deployer = makeAddr("deployer");

        curationToken = new MockERC20();
        newToken = new MockERC20();

        curation = new Curation();
        tokenLauncherFactory = new TokenLauncherFactory(address(curation));
    }
}
