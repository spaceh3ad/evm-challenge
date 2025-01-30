// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct CurationDetails {
    IERC20 curationToken;
    IERC20 newToken;
    uint256 distributionAmount;
    uint256 targetAmount;
}

enum CurationStatus {
    PENDING,
    ENDED
}
