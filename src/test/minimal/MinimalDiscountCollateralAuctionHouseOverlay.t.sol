pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalDiscountCollateralAuctionHouseOverlay} from "../../overlays/minimal/MinimalDiscountCollateralAuctionHouseOverlay.sol";

contract User {
    function doModifyParameters(MinimalDiscountCollateralAuctionHouseOverlay overlay, bytes32 parameter, address addr) public {
        overlay.modifyParameters(parameter, addr);
    }
}
contract DiscountCollateralAuctionHouse {
    address public systemCoinOracle;

    function modifyParameters(bytes32 parameter, address addr) public {
        if (parameter == "systemCoinOracle") systemCoinOracle = addr;
    }
}

contract MinimalDiscountCollateralAuctionHouseOverlayTest is DSTest {
    User user;
    DiscountCollateralAuctionHouse auctionHouse;
    MinimalDiscountCollateralAuctionHouseOverlay overlay;

    function setUp() public {
        user         = new User();
        auctionHouse = new DiscountCollateralAuctionHouse();
        overlay      = new MinimalDiscountCollateralAuctionHouseOverlay(address(auctionHouse));
    }

    function test_setup() public {
        assertEq(address(overlay.auctionHouse()), address(auctionHouse));
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
    function test_set_sys_coin_oracle() public {
        overlay.modifyParameters("systemCoinOracle", address(0x1));
        assertEq(auctionHouse.systemCoinOracle(), address(0x1));
    }
    function testFail_set_sys_coin_oracle_by_unauthed() public {
        user.doModifyParameters(overlay, "systemCoinOracle", address(0x1));
    }
    function testFail_set_other_param() public {
        overlay.modifyParameters("oracleRelayer", address(0x1));
    }
}
