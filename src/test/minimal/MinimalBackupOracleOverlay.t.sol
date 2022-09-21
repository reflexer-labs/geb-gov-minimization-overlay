pragma solidity 0.6.7;

import "ds-test/test.sol";
import "ds-value/value.sol";

import "../../overlays/minimal/MinimalBackupOracleOverlay.sol";

// import dsvalue

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract MinimalBackupOracleOverlayTest is DSTest {
    Hevm hevm;

    DSValue oracle0;
    DSValue oracle1;
    DSValue oracle2;
    MinimalBackupOracleOverlay overlay;

    address[] trustedOracles;
    uint256 entrustOracleDelay = 60 days;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        oracle0 = new DSValue();
        oracle1 = new DSValue();
        oracle2 = new DSValue();

        oracle0.updateResult(8);
        oracle1.updateResult(1);
        oracle2.updateResult(2);

        trustedOracles.push(address(oracle0));
        trustedOracles.push(address(oracle1));

        overlay = new MinimalBackupOracleOverlay(trustedOracles, entrustOracleDelay);
    }

    function test_setup() public {
        assertEq(overlay.trustedOracles(0), trustedOracles[0]);
        assertEq(overlay.trustedOracles(1), trustedOracles[1]);
        assertEq(overlay.entrustOracleDelay(), entrustOracleDelay);

        testRead(8, true);
    }

    function testRead(uint _val, bool _valid) internal {
        try overlay.read() returns (uint val) {
            assertEq(_val, val);
            assertTrue(_valid);
        } catch {
            assertTrue(!_valid);
        }

        (uint val, bool valid) = overlay.getResultWithValidity();
        assertEq(_val, val);
        assertTrue(valid == _valid);
    }

    function testFail_setup_empty_trusted_oracle() public {
        overlay = new MinimalBackupOracleOverlay(new address[](0), entrustOracleDelay);
    }

    function testFail_setup_null_trusted_oracle() public {
        trustedOracles[1] = address(0);
        overlay = new MinimalBackupOracleOverlay(trustedOracles, entrustOracleDelay);
    }

    function testFail_setup_null_delay() public {
        overlay = new MinimalBackupOracleOverlay(trustedOracles, 0);
    }

    function test_swap_oracle() public {
        overlay.swapOracle(1);
        testRead(1, true);

        overlay.swapOracle(0);
        testRead(8, true);
    }

    function testFail_swap_oracle_unauthed() public {
        overlay.removeAuthorization(address(this));
        overlay.swapOracle(0);
    }

    function test_schedule() public {
        address newOracle = address(oracle2);
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Replace, 1, newOracle);

        (
            MinimalBackupOracleOverlay.ChangeType action,
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
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Replace, 1, address(oracle2));
    }

    function testFail_schedule_already_scheduled() public {
        address newOracle = address(oracle2);
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Replace, 1, newOracle);
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Replace, 1, newOracle);
    }

    function testFail_schedule_null_oracle() public {
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Add, 0, address(0));
    }

    function testFail_schedule_null_oracle2() public {
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Replace, 1, address(0));
    }

    function testFail_schedule_invalid_oracle() public {
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Replace, 2, address(0xfab));
    }

    function testFail_schedule_invalid_oracle2() public {
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Remove, 2, address(0));
    }

    function test_execute_change() public {
        address newOracle = address(oracle2);
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Add, 0, newOracle);
        hevm.warp(now + entrustOracleDelay);
        overlay.removeAuthorization(address(this)); // anyone can execute
        overlay.executeChange();

        (
            MinimalBackupOracleOverlay.ChangeType action,
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
        address newOracle = address(oracle2);
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Add, 0, newOracle);
        overlay.cancelChange();
        overlay.executeChange();
    }

    function testFail_execute_change_unscheduled2() public {
        overlay.executeChange();
    }

    function testFail_execute_change_too_early() public {
        address newOracle = address(oracle2);
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Add, 0, newOracle);
        hevm.warp(now + entrustOracleDelay - 1);
        overlay.executeChange();
    }

    function test_add_trusted_oracle() public {
        address newOracle = address(oracle2);
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Add, 0, newOracle);
        hevm.warp(now + entrustOracleDelay);
        overlay.executeChange();
        assertEq(overlay.trustedOracles(2), newOracle);

        overlay.swapOracle(2);
        testRead(2, true);
    }

    function test_replace_trusted_oracle() public {
        address newOracle = address(oracle2);
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Replace, 0, newOracle);
        hevm.warp(now + entrustOracleDelay);
        overlay.executeChange();
        assertEq(overlay.trustedOracles(0), newOracle);

        overlay.swapOracle(0);
        testRead(2, true);
    }

    function test_remove_trusted_oracle() public {
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Remove, 0, address(0));
        hevm.warp(now + entrustOracleDelay);
        overlay.executeChange();
        assertEq(overlay.trustedOracles(0), trustedOracles[1]);

        try overlay.trustedOracles(1) { assertTrue(false); } catch {} // only one trusted oracle left
    }

    function test_remove_trusted_oracle2() public {
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Remove, 1, address(0));
        hevm.warp(now + entrustOracleDelay);
        overlay.executeChange();
        assertEq(overlay.trustedOracles(0), trustedOracles[0]);

        try overlay.trustedOracles(1) { assertTrue(false); } catch {} // only one trusted oracle left
    }

    function test_cancel_change() public {
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Remove, 1, address(0));
        overlay.cancelChange();

        (
            MinimalBackupOracleOverlay.ChangeType action,
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
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Remove, 1, address(0));
        overlay.cancelChange();
        overlay.cancelChange();
    }

    function testFail_cancel_change_unexistent2() public {
        overlay.cancelChange();
    }

    function testFail_cancel_change_unauthed() public {
        overlay.ScheduleChangeTrustedOracle(MinimalBackupOracleOverlay.ChangeType.Remove, 1, address(0));
        overlay.removeAuthorization(address(this));
        overlay.cancelChange();
    }

    function test_read_invalid_feed() public {
        oracle0.restartValue();
        testRead(8, false);
    }
}
