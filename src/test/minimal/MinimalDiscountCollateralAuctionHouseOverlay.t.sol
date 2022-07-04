pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalDiscountCollateralAuctionHouseOverlay} from "../../overlays/minimal/MinimalDiscountCollateralAuctionHouseOverlay.sol";

contract User {
    function doModifyParameters(MinimalDiscountCollateralAuctionHouseOverlay overlay, bytes32 parameter, address addr) public {
        overlay.modifyParameters(parameter, addr);
    }

    function doModifyParameters(MinimalDiscountCollateralAuctionHouseOverlay overlay, bytes32 parameter, uint256 value) public {
        overlay.modifyParameters(parameter, value);
    }
}
contract DiscountCollateralAuctionHouse {
    address public systemCoinOracle;

    uint256 public minDiscount;
    uint256 public maxDiscount;
    uint256 public perSecondDiscountUpdateRate;

    function modifyParameters(bytes32 parameter, address addr) public {
        if (parameter == "systemCoinOracle") systemCoinOracle = addr;
    }
    function modifyParameters(bytes32 parameter, uint256 value) public {
        if (parameter == "minDiscount") minDiscount = value;
        else if (parameter == "maxDiscount") maxDiscount = value;
        else if (parameter == "perSecondDiscountUpdateRate") perSecondDiscountUpdateRate = value;
    }
}

contract MinimalDiscountCollateralAuctionHouseOverlayTest is DSTest {
    User user;
    DiscountCollateralAuctionHouse auctionHouse;
    MinimalDiscountCollateralAuctionHouseOverlay overlay;

    uint256 discountLimit = 850000000000000000;

    function setUp() public {
        user         = new User();
        auctionHouse = new DiscountCollateralAuctionHouse();
        overlay      = new MinimalDiscountCollateralAuctionHouseOverlay(address(auctionHouse), discountLimit);
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
    function testFail_max_discount_below_limit() public {
        overlay.modifyParameters("maxDiscount", discountLimit - 1);
    }
    function testFail_set_invalid_uint() public {
        overlay.modifyParameters("something", 10);
    }
    function test_set_min_discount() public {
        overlay.modifyParameters("minDiscount", discountLimit + 1);
        assertEq(auctionHouse.minDiscount(), discountLimit + 1);
    }
    function test_set_max_discount() public {
        overlay.modifyParameters("maxDiscount", discountLimit + 10);
        assertEq(auctionHouse.maxDiscount(), discountLimit + 10);
    }
    function test_set_perSecondDiscountUpdateRate() public {
        overlay.modifyParameters("perSecondDiscountUpdateRate", 5);
        assertEq(auctionHouse.perSecondDiscountUpdateRate(), 5);
    }
}
