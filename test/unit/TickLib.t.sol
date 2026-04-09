// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { TickLib } from "../../src/lib/TickLib.sol";

contract TickLibTest is Test {
    // ---- toUsableTick -------------------------------------------------------

    function test_positiveTickExactMultiple() public pure {
        assertEq(TickLib.toUsableTick(60, 60), 60);
        assertEq(TickLib.toUsableTick(120, 60), 120);
    }

    function test_positiveTickRoundsDown() public pure {
        assertEq(TickLib.toUsableTick(59, 60), 0);
        assertEq(TickLib.toUsableTick(119, 60), 60);
        assertEq(TickLib.toUsableTick(1, 60), 0);
    }

    function test_zeroTick() public pure {
        assertEq(TickLib.toUsableTick(0, 60), 0);
    }

    function test_negativeTickExactMultiple() public pure {
        assertEq(TickLib.toUsableTick(-60, 60), -60);
        assertEq(TickLib.toUsableTick(-120, 60), -120);
    }

    function test_negativeTickFloorDiv() public pure {
        // floor(-1 / 60) = -1  →  -1 * 60 = -60
        assertEq(TickLib.toUsableTick(-1, 60), -60);
        // floor(-59 / 60) = -1  →  -60
        assertEq(TickLib.toUsableTick(-59, 60), -60);
        // floor(-61 / 60) = -2  →  -120
        assertEq(TickLib.toUsableTick(-61, 60), -120);
    }

    function test_tickSpacingOne() public pure {
        assertEq(TickLib.toUsableTick(887272, 1), 887272);
        assertEq(TickLib.toUsableTick(-887272, 1), -887272);
    }

    // ---- localWeightedSum ---------------------------------------------------

    function test_localWeightedSum_allZero() public pure {
        assertEq(TickLib.localWeightedSum(0, 0, 0, 0, 0), 0);
    }

    function test_localWeightedSum_centerOnly() public pure {
        // center has weight 2
        assertEq(TickLib.localWeightedSum(100, 0, 0, 0, 0), 200);
    }

    function test_localWeightedSum_allEqual() public pure {
        // 2*100 + 100 + 100 + 100 + 100 = 600
        assertEq(TickLib.localWeightedSum(100, 100, 100, 100, 100), 600);
    }

    function test_localWeightedSum_symmetry() public pure {
        // swap ±1 values should give same result
        uint256 a = TickLib.localWeightedSum(50, 10, 20, 5, 15);
        uint256 b = TickLib.localWeightedSum(50, 20, 10, 15, 5);
        assertEq(a, b);
    }

    function test_localWeightedSum_noOverflow() public pure {
        // All at max uint128 — should not overflow uint256
        uint128 m = type(uint128).max;
        uint256 s = TickLib.localWeightedSum(m, m, m, m, m);
        // 2*m + 4*m = 6*m; 6 * (2^128 - 1) < 2^256  ✓
        assertGt(s, 0);
    }

    // ---- fuzz ---------------------------------------------------------------

    /// @dev Property: toUsableTick result is always a multiple of tickSpacing
    function testFuzz_usableTickIsMultiple(int24 tick, int24 spacing) public pure {
        spacing = int24(bound(spacing, 1, 100)); // limit to avoid output overflow
        // bound tick to avoid overflow on output
        tick = int24(bound(tick, -1000000, 1000000));
        int24 usable = TickLib.toUsableTick(tick, spacing);
        assertEq(usable % spacing, 0);
    }

    /// @dev Property: usable tick <= tick (floor behaviour)
    function testFuzz_usableTickLeRawTick(int24 tick, int24 spacing) public pure {
        spacing = int24(bound(spacing, 1, 100));
        tick = int24(bound(tick, -1000000, 1000000));
        int24 usable = TickLib.toUsableTick(tick, spacing);
        assertLe(usable, tick);
    }
}
