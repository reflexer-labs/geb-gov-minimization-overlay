pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/single/LiquidationEngine.sol";

import "../../overlays/minimal/MinimalLiquidationEngineOverlay.sol";

contract SimpleSAFEEngine {
    function approveSAFEModification(address account) external {}
}
contract GenuineSaviour {
    address safeEngine;
    address liquidationEngine;

    constructor(address safeEngine_, address liquidationEngine_) public {
        safeEngine = safeEngine_;
        liquidationEngine = liquidationEngine_;
    }

    function saveSAFE(address liquidator, bytes32 collateralType, address safe) public returns (bool,uint256,uint256) {
        if (liquidator == liquidationEngine) {
          return (true, uint(-1), uint(-1));
        }
        else {
          return (true, 10900 ether, 0);
        }
    }
}
contract User {
    function doConnectSaviour(MinimalLiquidationEngineOverlay overlay, address saviour) public {
        overlay.connectSAFESaviour(saviour);
    }
    function doDisconnectSaviour(MinimalLiquidationEngineOverlay overlay, address saviour) public {
        overlay.disconnectSAFESaviour(saviour);
    }
}

contract MinimalLiquidationEngineOverlayTest is DSTest {
    LiquidationEngine liquidationEngine;
    SimpleSAFEEngine safeEngine;
    MinimalLiquidationEngineOverlay overlay;
    GenuineSaviour saviour;
    User user;

    uint256 minPenalty = 1090000000000000000;
    uint256 maxPenalty = 1150000000000000000;

    function setUp() public {
        safeEngine        = new SimpleSAFEEngine();
        liquidationEngine = new LiquidationEngine(address(safeEngine));
        overlay           = new MinimalLiquidationEngineOverlay(address(liquidationEngine), minPenalty, maxPenalty);
        saviour           = new GenuineSaviour(address(safeEngine), address(liquidationEngine));
        user              = new User();

        liquidationEngine.addAuthorization(address(overlay));
        liquidationEngine.modifyParameters("gold", "liquidationPenalty", 1020000000000000000);
    }

    function test_setup() public {
        assertEq(address(overlay.liquidationEngine()), address(liquidationEngine));
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
    function test_disconnect_saviour() public {
        overlay.connectSAFESaviour(address(saviour));
        overlay.disconnectSAFESaviour(address(saviour));
        assertEq(liquidationEngine.safeSaviours(address(saviour)), 0);
    }
    function testFail_connect_by_unauthed() public {
        user.doConnectSaviour(overlay, address(saviour));
    }
    function testFail_disconnect_by_unauthed() public {
        overlay.connectSAFESaviour(address(saviour));
        user.doDisconnectSaviour(overlay, address(saviour));
    }
    function testFail_set_too_high_penalty() public {
        overlay.modifyParameters("gold", "liquidationPenalty", maxPenalty + 1);
    }
    function testFail_set_too_low_penalty() public {
        overlay.modifyParameters("gold", "liquidationPenalty", minPenalty - 1);
    }
    function test_set_penalty() public {
        overlay.modifyParameters("gold", "liquidationPenalty", minPenalty + 1);
        (, uint256 liquidationPenalty, ) = liquidationEngine.collateralTypes("gold");
        assertEq(liquidationPenalty, minPenalty + 1);
    }
}
