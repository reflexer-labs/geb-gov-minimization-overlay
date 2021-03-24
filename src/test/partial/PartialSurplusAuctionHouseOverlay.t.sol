pragma solidity 0.6.7;

import "ds-test/test.sol";

import {BurningSurplusAuctionHouse, RecyclingSurplusAuctionHouse} from "geb/SurplusAuctionHouse.sol";

import "../../overlays/partial/PartialSurplusAuctionHouseOverlay.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract User {
    function modifyParameters(PartialSurplusAuctionHouseOverlay overlay, bytes32 parameter, uint256 val) external {
        overlay.modifyParameters(parameter, val);
    }
    function modifyParameters(PartialSurplusAuctionHouseOverlay overlay, bytes32 parameter, address data) external {
        overlay.modifyParameters(parameter, data);
    }
}

contract PartialSurplusAuctionHouseOverlayTest is DSTest {
    Hevm hevm;

    User user;

    BurningSurplusAuctionHouse surplusAuctionHouse;

    PartialSurplusAuctionHouseOverlay overlay;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        surplusAuctionHouse = new BurningSurplusAuctionHouse(address(0x1), address(0x2));

        overlay = new PartialSurplusAuctionHouseOverlay(address(surplusAuctionHouse));
        surplusAuctionHouse.addAuthorization(address(overlay));

        user = new User();
    }

    function test_setup() public {
        assertEq(address(overlay.surplusAuctionHouse()), address(surplusAuctionHouse));
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
    function test_modifyParam_uint() public {
        overlay.modifyParameters("bidIncrease", 10);
        assertEq(surplusAuctionHouse.bidIncrease(), 10);
    }
    function testFail_modifyParam_uint_unauthed() public {
        user.modifyParameters(overlay, "bidIncrease", 10);
    }
    function test_modifyParam_address() public {
        RecyclingSurplusAuctionHouse newAuctionHouse = new RecyclingSurplusAuctionHouse(address(0x1), address(0x2));

        overlay = new PartialSurplusAuctionHouseOverlay(address(newAuctionHouse));
        newAuctionHouse.addAuthorization(address(overlay));

        overlay.modifyParameters("protocolTokenBidReceiver", address(0x5));
        assertEq(newAuctionHouse.protocolTokenBidReceiver(), address(0x5));
    }
    function testFail_modifyParam_address_unauthed() public {
        RecyclingSurplusAuctionHouse newAuctionHouse = new RecyclingSurplusAuctionHouse(address(0x1), address(0x2));

        overlay = new PartialSurplusAuctionHouseOverlay(address(newAuctionHouse));
        newAuctionHouse.addAuthorization(address(overlay));

        user.modifyParameters(overlay, "protocolTokenBidReceiver", address(0x5));
    }
}
