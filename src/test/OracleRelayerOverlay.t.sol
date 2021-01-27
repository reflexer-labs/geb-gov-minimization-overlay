pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/OracleRelayer.sol";
import "geb/SAFEEngine.sol";

import "../overlays/OracleRelayerOverlay.sol";

contract User {
    function doRestartRedemptionRate(OracleRelayerOverlay overlay) external {
        overlay.restartRedemptionRate();
    }
}

contract OracleRelayerOverlayTest is DSTest {
    User user;

    SAFEEngine safeEngine;
    OracleRelayer oracleRelayer;

    OracleRelayerOverlay overlay;

    uint256 startingRedemptionRate = 10 ** 27 + 50;

    function setUp() public {
        user          = new User();
        safeEngine    = new SAFEEngine();
        oracleRelayer = new OracleRelayer(address(safeEngine));
        overlay       = new OracleRelayerOverlay(address(oracleRelayer));

        oracleRelayer.modifyParameters("redemptionRate", startingRedemptionRate);
        oracleRelayer.addAuthorization(address(overlay));
    }

    function test_setup() public {
        assertEq(address(overlay.oracleRelayer()), address(oracleRelayer));
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
