pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../overlays/minimal/MultiCollateralAuctionHouseOverlay.sol";

contract User {
    function doModifyParameters(MultiCollateralAuctionHouseOverlay overlay, address auctionHouse, bytes32 parameter, address addr) public {
        overlay.modifyParameters(auctionHouse, parameter, addr);
    }
}
contract FixedDiscountCollateralAuctionHouse {
    address public systemCoinOracle;

    function modifyParameters(bytes32 parameter, address addr) public {
        if (parameter == "systemCoinOracle") systemCoinOracle = addr;
    }
}

contract MultiCollateralAuctionHouseOverlayTest is DSTest {
    User user;
    FixedDiscountCollateralAuctionHouse auctionHouseOne;
    FixedDiscountCollateralAuctionHouse auctionHouseTwo;
    MultiCollateralAuctionHouseOverlay overlay;

    function setUp() public {
        user            = new User();
        auctionHouseOne = new FixedDiscountCollateralAuctionHouse();
        auctionHouseTwo = new FixedDiscountCollateralAuctionHouse();
        overlay         = new MultiCollateralAuctionHouseOverlay();
    }

    function test_set_sys_coin_oracle_house_one() public {
        overlay.modifyParameters(address(auctionHouseOne), "systemCoinOracle", address(0x1));
        assertEq(auctionHouseOne.systemCoinOracle(), address(0x1));
    }
    function test_set_sys_coin_oracle_house_two() public {
        overlay.modifyParameters(address(auctionHouseTwo), "systemCoinOracle", address(0x1));
        assertEq(auctionHouseTwo.systemCoinOracle(), address(0x1));
    }
    function testFail_set_sys_coin_by_unauthed() public {
        user.doModifyParameters(overlay, address(auctionHouseOne), "systemCoinOracle", address(0x1));
    }
    function testFail_set_different_param() public {
        overlay.modifyParameters(address(auctionHouseOne), "liquidationEngine", address(0x1));
    }
}
