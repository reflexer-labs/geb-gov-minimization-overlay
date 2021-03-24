pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/DebtAuctionHouse.sol";

import "../../overlays/partial/PartialDebtAuctionHouseOverlay.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract User {
    function modifyParameters(PartialDebtAuctionHouseOverlay overlay, bytes32 parameter, uint256 val) external {
        overlay.modifyParameters(parameter, val);
    }
}

contract PartialDebtAuctionHouseOverlayTest is DSTest {
    Hevm hevm;

    User user;

    DebtAuctionHouse debtAuctionHouse;

    PartialDebtAuctionHouseOverlay overlay;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        debtAuctionHouse = new DebtAuctionHouse(address(0x1), address(0x2));

        overlay = new PartialDebtAuctionHouseOverlay(address(debtAuctionHouse));
        debtAuctionHouse.addAuthorization(address(overlay));

        user = new User();
    }

    function test_setup() public {
        assertEq(address(overlay.debtAuctionHouse()), address(debtAuctionHouse));
        assertEq(overlay.authorizedAccounts(address(this)), 1);
    }
    function test_add_auth() public {
        overlay.addAuthorization(address(0x3));
        assertEq(overlay.authorizedAccounts(address(0x3)), 1);
    }
    function test_remove_auth() public {
        overlay.removeAuthorization(address(this));
        assertEq(overlay.authorizedAccounts(address(this)), 0);
    }
    function test_modifyParam() public {
        overlay.modifyParameters("bidDecrease", 10);
        assertEq(debtAuctionHouse.bidDecrease(), 10);
    }
    function testFail_modifyParam_unauthed() public {
        user.modifyParameters(overlay, "bidDecrease", 10);
    }
}
