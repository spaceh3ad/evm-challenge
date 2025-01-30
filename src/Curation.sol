// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./lib/Errors.sol";
import "./lib/Structs.sol";
import "./lib/Events.sol";

import {PoolHelper} from "./lib/PoolHelper.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract Curation is Initializable {
    using SafeERC20 for IERC20;

    address public positionManager;

    CurationDetails public curationDetails;
    CurationStatus public curationStatus;
    mapping(address => uint256) public stakedAmounts;

    modifier validateStatus(CurationStatus _status) {
        require(curationStatus == _status, Curation__InvalidStatus());
        _;
    }

    function initialize(
        CurationDetails calldata _curationDetails,
        address _positionManager
    ) public initializer {
        curationDetails = _curationDetails;
        positionManager = _positionManager;
        curationStatus = CurationStatus.PENDING;
    }

    function stake(
        uint256 amount
    ) public validateStatus(CurationStatus.PENDING) {
        uint256 currentBalance = curationDetails.curationToken.balanceOf(
            address(this)
        );

        if (currentBalance + amount >= curationDetails.targetAmount) {
            amount = curationDetails.targetAmount - currentBalance;
            curationStatus = CurationStatus.ENDED;
        }

        curationDetails.curationToken.safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        stakedAmounts[msg.sender] += amount;

        if (curationStatus == CurationStatus.ENDED) {
            address pool = _setUpPool();
            emit PoolCreated(pool);
        } else {
            emit Staked(msg.sender, amount);
        }
    }

    function unstake(
        uint256 amount
    ) public validateStatus(CurationStatus.PENDING) {
        require(
            curationDetails.curationToken.balanceOf(address(this)) <
                curationDetails.targetAmount,
            Curation__InsufficientBalance()
        );
        require(
            stakedAmounts[msg.sender] >= amount,
            Curation__InsufficientBalance()
        );
        stakedAmounts[msg.sender] -= amount;
        curationDetails.curationToken.safeTransfer(msg.sender, amount);
    }

    function claim() public validateStatus(CurationStatus.ENDED) {
        require(stakedAmounts[msg.sender] > 0, Curation__InsufficientBalance());

        uint256 amount = (stakedAmounts[msg.sender] *
            curationDetails.distributionAmount) / curationDetails.targetAmount;

        stakedAmounts[msg.sender] = 0;
        curationDetails.newToken.safeTransfer(msg.sender, amount);
    }

    function _setUpPool() internal returns (address pool) {
        (address token0, address token1) = PoolHelper.sortTokens(
            address(curationDetails.newToken),
            address(curationDetails.curationToken)
        );

        uint160 sqrtPriceX96 = PoolHelper.getSqrtPriceX96(
            curationDetails.targetAmount,
            curationDetails.distributionAmount
        );

        pool = INonfungiblePositionManager(positionManager)
            .createAndInitializePoolIfNecessary(
                token0,
                token1,
                uint24(3000),
                sqrtPriceX96
            );

        IERC20(token0).approve(address(positionManager), type(uint256).max);
        IERC20(token1).approve(address(positionManager), type(uint256).max);

        INonfungiblePositionManager(positionManager).mint(
            PoolHelper.getMintParams(
                IUniswapV3Pool(pool),
                curationDetails.targetAmount / 2,
                curationDetails.targetAmount / 2,
                address(this)
            )
        );
    }
}
