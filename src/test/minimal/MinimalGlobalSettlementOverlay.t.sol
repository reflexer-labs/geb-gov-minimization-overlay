pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../../overlays/minimal/MinimalGlobalSettlementOverlay.sol";

contract SimpleGlobalSettlement {
    function shutdownSystem() external {}
}
contract User {
    function doShutdownSystem(MinimalGlobalSettlementOverlay overlay) public {
        overlay.shutdownSystem();
    }
}

contract MinimalGlobalSettlementOverlayTest is DSTest {
    SimpleGlobalSettlement         globalSettlement;
    MinimalGlobalSettlementOverlay overlay;
    User                           user;

    function setUp() public {
        user             = new User();
        globalSettlement = new SimpleGlobalSettlement();
        overlay          = new MinimalGlobalSettlementOverlay(address(globalSettlement));
    }

    function testFail_shutdown_unauth() external {
        user.doShutdownSystem(overlay);
    }
    function test_shutdown() external {
        overlay.addAuthorization(address(user));
        user.doShutdownSystem(overlay);
    }
}
