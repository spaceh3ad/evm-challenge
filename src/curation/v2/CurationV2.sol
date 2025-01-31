// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "../v1/Curation.sol";

contract CurationV2 is Curation {
    bool public isV2;

    function setV2() external {
        isV2 = true;
    }
}
