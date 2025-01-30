// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./Curation.sol";

/// @custom:oz-upgrades-from Curation
contract CurationV2 is Curation {
    bool public isV2;

    function setV2() public {
        isV2 = true;
    }
}
