// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MockERC20} from "forge-std/mocks/MockERC20.sol";

contract Token is MockERC20 {
    constructor(string memory _name, string memory _symbol) {
        initialize(_name, _symbol, 18);
        _mint(msg.sender, 1_000_000 ether);
    }
}
