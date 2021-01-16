pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./GebGovMinimizationOverlay.sol";

contract GebGovMinimizationOverlayTest is DSTest {
    GebGovMinimizationOverlay overlay;

    function setUp() public {
        overlay = new GebGovMinimizationOverlay();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
