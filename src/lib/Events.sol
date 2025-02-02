// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

event ImplementationUpgraded(address indexed newImplementation);
event SubmissionCreated(address indexed token);

event Staked(address indexed user, uint256 indexed amount);
event Unstake(address indexed user, uint256 indexed amount);
event Claim(address indexed user, uint256 indexed amount);
event PoolCreated(address indexed pool);
