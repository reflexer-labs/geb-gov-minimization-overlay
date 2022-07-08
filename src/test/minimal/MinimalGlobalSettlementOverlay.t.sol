pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../../overlays/minimal/MinimalGlobalSettlementOverlay.sol";

contract SimpleGlobalSettlement {
    function shutdownSystem() external {}
}
contract User {
    function doStartShutdown(MinimalGlobalSettlementOverlay overlay) public {
        overlay.startShutdownProcedure();
    }

    function doStopShutdown(MinimalGlobalSettlementOverlay overlay) public {
        overlay.stopShutdownProcedure();
    }

    function doShutdownSystem(MinimalGlobalSettlementOverlay overlay) public {
        overlay.shutdownSystem();
    }
}
abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract MinimalGlobalSettlementOverlayTest is DSTest {
    Hevm hevm;

    SimpleGlobalSettlement         globalSettlement;
    MinimalGlobalSettlementOverlay overlay;
    User                           user;

    uint256 shutdownDelay = 28 * 24 * 3600;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        user             = new User();
        globalSettlement = new SimpleGlobalSettlement();
        overlay          = new MinimalGlobalSettlementOverlay(address(globalSettlement), shutdownDelay);
    }

    function testFail_shutdown_unauth() external {
        user.doStartShutdown(overlay);
    }
    function testFail_remove_shutdown() external {
        overlay.startShutdownProcedure();
        user.doStopShutdown(overlay);
    }
    function test_remove_shutdown() external {
        overlay.startShutdownProcedure();
        assertEq(overlay.settlementExecutionDate(), now + shutdownDelay);

        hevm.warp(now + 10);
        overlay.stopShutdownProcedure();

        assertEq(overlay.settlementExecutionDate(), 0);
    }
    function testFail_shutdown_without_having_started() external {
        overlay.startShutdownProcedure();
        hevm.warp(now + 10);
        overlay.stopShutdownProcedure();

        assertEq(overlay.settlementExecutionDate(), 0);
        overlay.shutdownSystem();
    }
    function testFail_shutdown_before_date() external {
        overlay.startShutdownProcedure();
        hevm.warp(now + 10);
        overlay.shutdownSystem();
    }
    function testFail_simple_shutdown() external {
        assertEq(overlay.settlementExecutionDate(), 0);
        overlay.shutdownSystem();
    }
    function test_shutdown() external {
        overlay.startShutdownProcedure();
        assertEq(overlay.settlementExecutionDate(), now + shutdownDelay);
        hevm.warp(now + shutdownDelay + 1);

        overlay.shutdown();
        assertEq(overlay.settlementExecutionDate(), 0);
    }
}
