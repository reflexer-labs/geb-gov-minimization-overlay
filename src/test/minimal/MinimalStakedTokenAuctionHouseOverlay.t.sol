pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../../overlays/minimal/MinimalStakedTokenAuctionHouseOverlay.sol";

contract SimpleStakedTokenAuctionHouse {
    bool    public isEnabled = true;
    address public tokenBurner;

    function modifyParameters(bytes32, address data) external {
        tokenBurner = data;
    }

    function disableContract() external {
        isEnabled = false;
    }
}
contract User {
    function doModifyParameters(MinimalStakedTokenAuctionHouseOverlay overlay, address data) external {
        overlay.modifyParameters("tokenBurner", data);
    }

    function doDisableContract(MinimalStakedTokenAuctionHouseOverlay overlay) external {
        overlay.disableContract();
    }
}

contract MinimalStakedTokenAuctionHouseOverlayTest is DSTest {
    SimpleStakedTokenAuctionHouse         auctionHouse;
    MinimalStakedTokenAuctionHouseOverlay overlay;
    User                                  user;

    function setUp() public {
        user         = new User();
        auctionHouse = new SimpleStakedTokenAuctionHouse();
        overlay      = new MinimalStakedTokenAuctionHouseOverlay(address(auctionHouse));
    }

    function testFail_disable_house_unauthed() external {
        user.doDisableContract(overlay);
    }
    function test_disable_house() external {
        overlay.disableContract();
        assertTrue(!auctionHouse.isEnabled());
    }
    function testFail_modify_params_unauthed() external {
        user.doModifyParameters(overlay, address(0x123));
    }
    function testFail_modify_invalid_param() external {
        overlay.modifyParameters("random", address(0x123));
    }
    function test_modify_tokenBurner() external {
        overlay.modifyParameters("tokenBurner", address(0x123));
        assertTrue(address(0x123) == auctionHouse.tokenBurner());
    }
}
