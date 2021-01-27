pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../overlays/StabilityFeeTreasuryOverlay.sol";

contract User {
    function doTakeFunds(StabilityFeeTreasuryOverlay overlay, address dst, uint256 amount) external {
        overlay.takeFunds(dst, amount);
    }
}
contract StabilityFeeTreasury {
    function takeFunds(address dst, uint256 amount) external {
        return;
    }
}

contract StabilityFeeTreasuryOverlayTest is DSTest {
    User user;
    StabilityFeeTreasury treasury;
    StabilityFeeTreasuryOverlay overlay;

    function setUp() public {
        user     = new User();
        treasury = new StabilityFeeTreasury();
        overlay  = new StabilityFeeTreasuryOverlay(address(treasury));
    }
    function test_setup() public {
        assertEq(address(overlay.treasury()), address(treasury));
    }
    function test_take_funds() public {
        overlay.takeFunds(address(0x1), 1 ether);
    }
    function testFail_take_funds_unauthed() public {
        user.doTakeFunds(overlay, address(0x1), 1 ether);
    }
}
