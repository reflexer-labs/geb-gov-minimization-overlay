pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../../overlays/minimal/MinimalOSMOverlay.sol";

contract OSMMock {
    address public priceSource;

    function changePriceSource(address oracle_) external {
        priceSource = oracle_;
    }
}

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract MinimalOSMOverlayTest is DSTest {
    Hevm hevm;

    OSMMock           OSM;
    MinimalOSMOverlay overlay;

    address[] trustedOracles;
    uint256 entrustOracleDelay = 28 days;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);


        trustedOracles.push(address(0x20));
        trustedOracles.push(address(0x21));

        // user             = new User();
        OSM     = new OSMMock();
        overlay = new MinimalOSMOverlay(address(OSM), trustedOracles, entrustOracleDelay);
    }

    function test_setup() public {
        assertEq(address(overlay.OSM()), address(OSM));
        assertEq(overlay.trustedOracles(0), trustedOracles[0]);
        assertEq(overlay.trustedOracles(1), trustedOracles[1]);
        assertEq(overlay.entrustOracleDelay(), entrustOracleDelay);
    }

    function testFail_setup_null_osm() public {
        overlay = new MinimalOSMOverlay(address(0), trustedOracles, entrustOracleDelay);
    }

    function testFail_setup_null_trusted_oracle() public {
        trustedOracles[1] = address(0);
        overlay = new MinimalOSMOverlay(address(OSM), trustedOracles, entrustOracleDelay);
    }

    function testFail_setup_null_delay() public {
        overlay = new MinimalOSMOverlay(address(OSM), trustedOracles, 0);
    }

    function test_swap_oracle() public {
        overlay.swapOracle(1);
        assertEq(OSM.priceSource(), trustedOracles[1]);

        overlay.swapOracle(0);
        assertEq(OSM.priceSource(), trustedOracles[0]);
    }

    function testFail_swap_oracle_unauthed() public {
        overlay.removeAuthorization(address(this));
        overlay.swapOracle(0);
    }

    function test_schedule() public {
        address newOracle = address(0xfab);
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Replace, 1, newOracle);

        (
            MinimalOSMOverlay.ChangeType action,
            uint256 executionTimestamp,
            uint256 oracleIndex,
            address newOracle_
        ) = overlay.scheduledChange();

        assertEq(uint256(action), 2);
        assertEq(executionTimestamp, now + entrustOracleDelay);
        assertEq(oracleIndex, 1);
        assertEq(newOracle_, newOracle);
    }

    function testFail_schedule_unauthed() public {
        overlay.removeAuthorization(address(this));
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Replace, 1, address(0xfab));
    }

    function testFail_schedule_already_scheduled() public {
        address newOracle = address(0xfab);
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Replace, 1, newOracle);
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Replace, 1, newOracle);
    }

    function testFail_schedule_null_oracle() public {
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Add, 0, address(0));
    }

    function testFail_schedule_null_oracle2() public {
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Replace, 1, address(0));
    }

    function testFail_schedule_invalid_oracle() public {
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Replace, 2, address(0xfab));
    }

    function testFail_schedule_invalid_oracle2() public {
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Remove, 2, address(0));
    }

    function test_execute_change() public {
        address newOracle = address(0xfab);
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Add, 0, newOracle);
        hevm.warp(now + entrustOracleDelay);
        overlay.removeAuthorization(address(this)); // anyone can execute
        overlay.executeChange();

        (
            MinimalOSMOverlay.ChangeType action,
            uint256 executionTimestamp,
            uint256 oracleIndex,
            address oracle
        ) = overlay.scheduledChange();

        assertEq(uint256(action), 0);
        assertEq(executionTimestamp, 0);
        assertEq(oracleIndex, 0);
        assertEq(oracle, address(0));

        assertEq(overlay.trustedOracles(2), newOracle);
    }

    function testFail_execute_change_unscheduled() public {
        address newOracle = address(0xfab);
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Add, 0, newOracle);
        overlay.cancelChange();
        overlay.executeChange();
    }

    function testFail_execute_change_unscheduled2() public {
        overlay.executeChange();
    }

    function testFail_execute_change_too_early() public {
        address newOracle = address(0xfab);
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Add, 0, newOracle);
        hevm.warp(now + entrustOracleDelay - 1);
        overlay.executeChange();
    }

    function test_add_trusted_oracle() public {
        address newOracle = address(0xfab);
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Add, 0, newOracle);
        hevm.warp(now + entrustOracleDelay);
        overlay.executeChange();
        assertEq(overlay.trustedOracles(2), newOracle);

        overlay.swapOracle(2);
        assertEq(OSM.priceSource(), newOracle);
    }

    function test_replace_trusted_oracle() public {
        address newOracle = address(0xfab);
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Replace, 0, newOracle);
        hevm.warp(now + entrustOracleDelay);
        overlay.executeChange();
        assertEq(overlay.trustedOracles(0), newOracle);

        overlay.swapOracle(0);
        assertEq(OSM.priceSource(), newOracle);
    }

    function test_remove_trusted_oracle() public {
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Remove, 0, address(0));
        hevm.warp(now + entrustOracleDelay);
        overlay.executeChange();
        assertEq(overlay.trustedOracles(0), trustedOracles[1]);

        try overlay.trustedOracles(1) { assertTrue(false); } catch {} // only one trusted oracle left
    }

    function test_remove_trusted_oracle2() public {
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Remove, 1, address(0));
        hevm.warp(now + entrustOracleDelay);
        overlay.executeChange();
        assertEq(overlay.trustedOracles(0), trustedOracles[0]);

        try overlay.trustedOracles(1) { assertTrue(false); } catch {} // only one trusted oracle left
    }

    function test_cancel_change() public {
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Remove, 1, address(0));
        overlay.cancelChange();

        (
            MinimalOSMOverlay.ChangeType action,
            uint256 executionTimestamp,
            uint256 oracleIndex,
            address newOracle
        ) = overlay.scheduledChange();

        assertEq(uint256(action), 0);
        assertEq(executionTimestamp, 0);
        assertEq(oracleIndex, 0);
        assertEq(newOracle, address(0));
    }

    function testFail_cancel_change_unexistent() public {
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Remove, 1, address(0));
        overlay.cancelChange();
        overlay.cancelChange();
    }

    function testFail_cancel_change_unexistent2() public {
        overlay.cancelChange();
    }

    function testFail_cancel_change_unauthed() public {
        overlay.ScheduleChangeTrustedOracle(MinimalOSMOverlay.ChangeType.Remove, 1, address(0));
        overlay.removeAuthorization(address(this));
        overlay.cancelChange();
    }
}
