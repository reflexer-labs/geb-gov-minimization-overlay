pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../../overlays/minimal/MinimalMultiCollateralAuctionHouseOverlay.sol";

contract User {
    function doModifyParameters(MinimalMultiCollateralAuctionHouseOverlay overlay, address auctionHouse, bytes32 parameter, address addr) public {
        overlay.modifyParameters(auctionHouse, parameter, addr);
    }
}
contract FixedDiscountCollateralAuctionHouse {
    address public systemCoinOracle;

    function modifyParameters(bytes32 parameter, address addr) public {
        if (parameter == "systemCoinOracle") systemCoinOracle = addr;
    }
}

contract MinimalMultiCollateralAuctionHouseOverlayTest is DSTest {
    User user;
    FixedDiscountCollateralAuctionHouse auctionHouseOne;
    FixedDiscountCollateralAuctionHouse auctionHouseTwo;
    MinimalMultiCollateralAuctionHouseOverlay overlay;

    function setUp() public {
        user            = new User();
        auctionHouseOne = new FixedDiscountCollateralAuctionHouse();
        auctionHouseTwo = new FixedDiscountCollateralAuctionHouse();
        overlay         = new MinimalMultiCollateralAuctionHouseOverlay();
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
