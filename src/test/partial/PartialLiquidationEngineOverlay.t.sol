pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/LiquidationEngine.sol";
import "geb/SAFEEngine.sol";

import "../../overlays/partial/PartialLiquidationEngineOverlay.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract User {
    function connectSAFESaviour(PartialLiquidationEngineOverlay overlay, address saviour) external {
        overlay.connectSAFESaviour(saviour);
    }
    function disconnectSAFESaviour(PartialLiquidationEngineOverlay overlay, address saviour) external {
        overlay.disconnectSAFESaviour(saviour);
    }
    function modifyParameters(PartialLiquidationEngineOverlay overlay, bytes32 parameter, uint256 val) external {
        overlay.modifyParameters(parameter, val);
    }
    function modifyParameters(
        PartialLiquidationEngineOverlay overlay,
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) external {
        overlay.modifyParameters(collateralType, parameter, data);
    }
    function modifyParameters(
        PartialLiquidationEngineOverlay overlay,
        bytes32 collateralType,
        bytes32 parameter,
        address data
    ) external {
        overlay.modifyParameters(collateralType, parameter, data);
    }
    function removeCoinsFromAuction(PartialLiquidationEngineOverlay overlay, uint256 rad) public {
        overlay.removeCoinsFromAuction(rad);
    }
}

contract ReentrantSaviour {
    address liquidationEngine;

    constructor(address liquidationEngine_) public {
        liquidationEngine = liquidationEngine_;
    }

    function saveSAFE(address liquidator,bytes32 collateralType,address safe) public returns (bool,uint256,uint256) {
        if (liquidator == liquidationEngine) {
          return (true, uint(-1), uint(-1));
        }
        else {
          LiquidationEngine(msg.sender).liquidateSAFE(collateralType, safe);
          return (true, 1, 1);
        }
    }
}

contract PartialLiquidationEngineOverlayTest is DSTest {
    Hevm hevm;

    User user;

    SAFEEngine safeEngine;
    LiquidationEngine liquidationEngine;
    ReentrantSaviour saviour;

    PartialLiquidationEngineOverlay overlay;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        safeEngine = new SAFEEngine();
        liquidationEngine = new LiquidationEngine(address(safeEngine));

        saviour = new ReentrantSaviour(address(liquidationEngine));

        overlay = new PartialLiquidationEngineOverlay(address(liquidationEngine));
        liquidationEngine.addAuthorization(address(overlay));

        user = new User();
    }

    function test_setup() public {
        assertEq(address(overlay.liquidationEngine()), address(liquidationEngine));
        assertEq(overlay.authorizedAccounts(address(this)), 1);
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
    function test_connect_saviour() public {
        overlay.connectSAFESaviour(address(saviour));
        assertEq(liquidationEngine.safeSaviours(address(saviour)), 1);
    }
    function testFail_connect_saviour_unauthed() public {
        user.connectSAFESaviour(overlay, address(saviour));
    }
    function test_disconnect_saviour() public {
        overlay.connectSAFESaviour(address(saviour));
        overlay.disconnectSAFESaviour(address(saviour));

        assertEq(liquidationEngine.safeSaviours(address(saviour)), 0);
    }
    function testFail_disconnect_saviour_unauthed() public {
        overlay.connectSAFESaviour(address(saviour));
        user.disconnectSAFESaviour(overlay, address(saviour));
    }
    function test_modifyParams_uint() public {
        overlay.modifyParameters("onAuctionSystemCoinLimit", 1);
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(), 1);
    }
    function testFail_modifyParams_uint_unauthed() public {
        user.modifyParameters(overlay, "onAuctionSystemCoinLimit", 1);
    }
    function test_modifyParams_collateral_type_uint() public {
        overlay.modifyParameters("ETH-A", "liquidationPenalty", 1E18 + 1);
        (, uint256 liquidationPenalty, ) = liquidationEngine.collateralTypes("ETH-A");
        assertEq(liquidationPenalty, 1E18 + 1);
    }
    function testFail_modifyParams_collateral_type_uint_unauthed() public {
        user.modifyParameters(overlay, "ETH-A", "liquidationPenalty", 1E18 + 1);
    }
    function test_modifyParams_collateral_type_address() public {
        overlay.modifyParameters("ETH-A", "collateralAuctionHouse", address(0x1));
        (address auctionHouse, , ) = liquidationEngine.collateralTypes("ETH-A");
        assertEq(auctionHouse, address(0x1));
    }
    function testFail_modifyParams_collateral_type_address_unauthed() public {
        user.modifyParameters(overlay, "ETH-A", "collateralAuctionHouse", address(0x1));
    }
}
