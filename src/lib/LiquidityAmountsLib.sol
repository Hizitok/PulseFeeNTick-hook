// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { FullMath } from "v4-core/src/libraries/FullMath.sol";

/// @title LiquidityAmountsLib
/// @notice Liquidity ↔ token amount conversions for Uniswap v4 positions.
///         Uses v4-periphery implementation for getLiquidityForAmounts.
///         Provides getAmountsForLiquidity (the latter is absent from v4-periphery).
library LiquidityAmountsLib {
    uint256 internal constant Q96 = 0x1000000000000000000000000; // 2^96

    // -----------------------------------------------------------------------
    // Amounts → liquidity (using v4-periphery logic)
    // -----------------------------------------------------------------------

    function getLiquidityForAmount0(
        uint160 sqrtPriceAx96,
        uint160 sqrtPriceBx96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (amount0 == 0) return 0;
        if (sqrtPriceAx96 > sqrtPriceBx96) {
            (sqrtPriceAx96, sqrtPriceBx96) = (sqrtPriceBx96, sqrtPriceAx96);
        }

        uint256 intermediate = FullMath.mulDiv(sqrtPriceAx96, sqrtPriceBx96, Q96);
        liquidity =
            uint128(FullMath.mulDiv(amount0, intermediate, sqrtPriceBx96 - sqrtPriceAx96));
    }

    function getLiquidityForAmount1(
        uint160 sqrtPriceAx96,
        uint160 sqrtPriceBx96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (amount1 == 0) return 0;
        if (sqrtPriceAx96 > sqrtPriceBx96) {
            (sqrtPriceAx96, sqrtPriceBx96) = (sqrtPriceBx96, sqrtPriceAx96);
        }

        liquidity = uint128(FullMath.mulDiv(amount1, Q96, sqrtPriceBx96 - sqrtPriceAx96));
    }

    /// @notice Compute the maximum liquidity obtainable for a given amount of token0 and token1
    function getLiquidityForAmounts(
        uint160 sqrtPriceX96,
        uint160 sqrtPriceAx96,
        uint160 sqrtPriceBx96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtPriceAx96 > sqrtPriceBx96) {
            (sqrtPriceAx96, sqrtPriceBx96) = (sqrtPriceBx96, sqrtPriceAx96);
        }

        if (sqrtPriceX96 <= sqrtPriceAx96) {
            liquidity = getLiquidityForAmount0(sqrtPriceAx96, sqrtPriceBx96, amount0);
        } else if (sqrtPriceX96 < sqrtPriceBx96) {
            uint128 liquidity0 =
                getLiquidityForAmount0(sqrtPriceX96, sqrtPriceBx96, amount0);
            uint128 liquidity1 =
                getLiquidityForAmount1(sqrtPriceAx96, sqrtPriceX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtPriceAx96, sqrtPriceBx96, amount1);
        }
    }

    // -----------------------------------------------------------------------
    // Liquidity → amounts
    // -----------------------------------------------------------------------

    /// @notice token0 needed to provide `liquidity` in range [sqrtPA, sqrtPB] at current price `sqrtP`.
    function getAmount0ForLiquidity(uint160 sqrtPA, uint160 sqrtPB, uint128 liquidity)
        internal
        pure
        returns (uint256)
    {
        if (sqrtPA > sqrtPB) (sqrtPA, sqrtPB) = (sqrtPB, sqrtPA);
        return FullMath.mulDiv(uint256(liquidity) << 96, sqrtPB - sqrtPA, sqrtPB) / sqrtPA;
    }

    /// @notice token1 needed to provide `liquidity` in range [sqrtPA, sqrtPB] at current price `sqrtP`.
    function getAmount1ForLiquidity(uint160 sqrtPA, uint160 sqrtPB, uint128 liquidity)
        internal
        pure
        returns (uint256)
    {
        if (sqrtPA > sqrtPB) (sqrtPA, sqrtPB) = (sqrtPB, sqrtPA);
        return FullMath.mulDiv(liquidity, sqrtPB - sqrtPA, Q96);
    }

    /// @notice Compute (amount0, amount1) required for `liquidity` given current sqrt price `sqrtP`.
    function getAmountsForLiquidity(
        uint160 sqrtP,
        uint160 sqrtPA,
        uint160 sqrtPB,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtPA > sqrtPB) (sqrtPA, sqrtPB) = (sqrtPB, sqrtPA);
        if (sqrtP <= sqrtPA) {
            amount0 = getAmount0ForLiquidity(sqrtPA, sqrtPB, liquidity);
        } else if (sqrtP < sqrtPB) {
            amount0 = getAmount0ForLiquidity(sqrtP, sqrtPB, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtPA, sqrtP, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtPA, sqrtPB, liquidity);
        }
    }
}
