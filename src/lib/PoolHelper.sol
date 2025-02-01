// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library PoolHelper {
    function initPool(
        address token0,
        address token1,
        uint24 fee,
        uint160 initalPrice,
        INonfungiblePositionManager positionManager
    ) public returns (address) {
        return
            positionManager.createAndInitializePoolIfNecessary(
                token0,
                token1,
                fee,
                initalPrice
            );
    }

    function getFullRange(
        int24 tickSpacing
    ) public pure returns (int24 tickLower, int24 tickUpper) {
        tickLower = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        tickUpper = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
    }

    function getMintParams(
        IUniswapV3Pool pool,
        uint256 amount0Desired,
        uint256 amount1Desired,
        address recipient
    ) internal view returns (INonfungiblePositionManager.MintParams memory) {
        uint24 fee = pool.fee();
        int24 tickSpacing = pool.tickSpacing();

        (int24 tickLower, int24 tickUpper) = getFullRange(tickSpacing);

        return
            INonfungiblePositionManager.MintParams(
                pool.token0(),
                pool.token1(),
                fee,
                tickLower,
                tickUpper,
                amount0Desired,
                amount1Desired,
                0,
                0,
                recipient,
                block.timestamp + 100
            );
    }

    function getSqrtPriceX96(
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint160) {
        uint256 ratioX128 = (amount1 << 128) / amount0;
        uint256 sqrtRatioX64 = Math.sqrt(ratioX128);
        return uint160(sqrtRatioX64 << 32);
    }

    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Identical tokens");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }
}
