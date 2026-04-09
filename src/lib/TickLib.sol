// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title TickLib
/// @notice Helpers for usable tick normalization and local weighted volume sum.
library TickLib {
    /// @notice Convert a raw tick to the usable (tickSpacing-aligned) tick using floor division.
    ///         Solidity truncates toward zero, so negative ticks need manual correction.
    /// @param tick        Raw tick from pool state
    /// @param tickSpacing Pool tick spacing
    /// @return Usable tick (floor(tick / tickSpacing) * tickSpacing)
    function toUsableTick(int24 tick, int24 tickSpacing) internal pure returns (int24) {
        int24 q = tick / tickSpacing;
        // Floor correction: if tick is negative and not perfectly divisible, subtract 1
        if (tick < 0 && tick % tickSpacing != 0) q -= 1;
        return q * tickSpacing;
    }

    /// @notice Compute the local weighted volume sum used in the fee formula.
    ///         sum = center*2 + (t-1) + (t+1) + (t-2) + (t+2)
    /// @param center  Decayed volume at center usable tick t
    /// @param minus1  Decayed volume at t - tickSpacing
    /// @param plus1   Decayed volume at t + tickSpacing
    /// @param minus2  Decayed volume at t - 2*tickSpacing
    /// @param plus2   Decayed volume at t + 2*tickSpacing
    function localWeightedSum(
        uint128 center,
        uint128 minus1,
        uint128 plus1,
        uint128 minus2,
        uint128 plus2
    ) internal pure returns (uint256) {
        return uint256(center) * 2 + uint256(minus1) + uint256(plus1) + uint256(minus2)
            + uint256(plus2);
    }
}
