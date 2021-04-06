pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../../overlays/minimal/MinimalStabilityFeeTreasuryOverlay.sol";

contract User {
    function doTakeFunds(MinimalStabilityFeeTreasuryOverlay overlay, address dst, uint256 amount) external {
        overlay.takeFunds(dst, amount);
    }
}
contract StabilityFeeTreasury {
    function takeFunds(address dst, uint256 amount) external {
        return;
    }
}

contract MinimalStabilityFeeTreasuryOverlayTest is DSTest {
    User user;
    StabilityFeeTreasury treasury;
    MinimalStabilityFeeTreasuryOverlay overlay;

    function setUp() public {
        user     = new User();
        treasury = new StabilityFeeTreasury();
        overlay  = new MinimalStabilityFeeTreasuryOverlay(address(treasury));
    }

    function test_setup() public {
        assertEq(address(overlay.treasury()), address(treasury));
    }
    function test_add_auth() public {
        overlay.addAuthorization(address(0x3));
        assertEq(overlay.authorizedAccounts(address(0x3)), 1);
    }
    function test_remove_auth() public {
        overlay.addAuthorization(address(this));
        overlay.removeAuthorization(address(this));
        assertEq(overlay.authorizedAccounts(address(this)), 0);
    }
    function test_take_funds() public {
        overlay.takeFunds(address(0x1), 1 ether);
    }
    function testFail_take_funds_unauthed() public {
        user.doTakeFunds(overlay, address(0x1), 1 ether);
    }
}
