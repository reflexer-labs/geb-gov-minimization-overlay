pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/LiquidationEngine.sol";

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

    function setUp() public {
        safeEngine        = new SimpleSAFEEngine();
        liquidationEngine = new LiquidationEngine(address(safeEngine));
        overlay           = new MinimalLiquidationEngineOverlay(address(liquidationEngine));
        saviour           = new GenuineSaviour(address(safeEngine), address(liquidationEngine));
        user              = new User();

        liquidationEngine.addAuthorization(address(overlay));
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
}
