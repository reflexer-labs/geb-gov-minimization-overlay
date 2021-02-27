pragma solidity 0.6.7;

import "ds-test/test.sol";

import {DiscountCollateralAuctionHouseOverlay} from "../overlays/DiscountCollateralAuctionHouseOverlay.sol";

contract User {
    function doModifyParameters(DiscountCollateralAuctionHouseOverlay overlay, bytes32 parameter, address addr) public {
        overlay.modifyParameters(parameter, addr);
    }
}
contract DiscountCollateralAuctionHouse {
    address public systemCoinOracle;

    function modifyParameters(bytes32 parameter, address addr) public {
        if (parameter == "systemCoinOracle") systemCoinOracle = addr;
    }
}

contract DiscountCollateralAuctionHouseOverlayTest is DSTest {
    User user;
    DiscountCollateralAuctionHouse auctionHouse;
    DiscountCollateralAuctionHouseOverlay overlay;

    function setUp() public {
        user         = new User();
        auctionHouse = new DiscountCollateralAuctionHouse();
        overlay      = new DiscountCollateralAuctionHouseOverlay(address(auctionHouse));
    }

    function test_setup() public {
        assertEq(address(overlay.auctionHouse()), address(auctionHouse));
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
