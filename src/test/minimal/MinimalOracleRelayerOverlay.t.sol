pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/single/OracleRelayer.sol";
import "geb/single/SAFEEngine.sol";

import "../../overlays/minimal/MinimalOracleRelayerOverlay.sol";

contract User {
    function doRestartRedemptionRate(MinimalOracleRelayerOverlay overlay) external {
        overlay.restartRedemptionRate();
    }
}

contract MinimalOracleRelayerOverlayTest is DSTest {
    User user;

    SAFEEngine safeEngine;
    OracleRelayer oracleRelayer;

    MinimalOracleRelayerOverlay overlay;

    uint256 startingRedemptionRate = 10 ** 27 + 50;

    function setUp() public {
        user          = new User();
        safeEngine    = new SAFEEngine();
        oracleRelayer = new OracleRelayer(address(safeEngine));
        overlay       = new MinimalOracleRelayerOverlay(address(oracleRelayer));

        oracleRelayer.modifyParameters("redemptionRate", startingRedemptionRate);
        oracleRelayer.addAuthorization(address(overlay));
    }

    function test_setup() public {
        assertEq(address(overlay.oracleRelayer()), address(oracleRelayer));
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
    function test_restart_rate() public {
        assertEq(oracleRelayer.redemptionRate(), startingRedemptionRate);
        overlay.restartRedemptionRate();
        assertEq(oracleRelayer.redemptionRate(), 10 ** 27);
    }
    function testFail_restart_rate_by_unauthed() public {
        user.doRestartRedemptionRate(overlay);
    }
}
