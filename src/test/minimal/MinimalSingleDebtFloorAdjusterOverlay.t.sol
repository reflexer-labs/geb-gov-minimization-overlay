pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalSingleDebtFloorAdjusterOverlay} from "../../overlays/minimal/MinimalSingleDebtFloorAdjusterOverlay.sol";

contract User {
    function doModifyParameters(MinimalSingleDebtFloorAdjusterOverlay overlay, bytes32 parameter, uint256 data) public {
        overlay.modifyParameters(parameter, data);
    }
}
contract SingleDebtFloorAdjuster {
    uint256 public lastUpdateTime;

    function modifyParameters(bytes32 parameter, uint256 data) public {
        if (parameter == "lastUpdateTime") lastUpdateTime = data;
    }
}
abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract MinimalSingleDebtFloorAdjusterOverlayTest is DSTest {
    Hevm hevm;

    User user;
    SingleDebtFloorAdjuster adjuster;
    MinimalSingleDebtFloorAdjusterOverlay overlay;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        user     = new User();
        adjuster = new SingleDebtFloorAdjuster();
        overlay  = new MinimalSingleDebtFloorAdjusterOverlay(address(adjuster));
    }

    function test_setup() public {
        assertEq(address(overlay.adjuster()), address(adjuster));
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
    function testFail_set_lastUpdateTime_unauthed() public {
        user.doModifyParameters(overlay, "lastUpdateTime", now + 1);
    }
    function testFail_set_random_var() public {
        overlay.modifyParameters("randomVar", 10);
    }
    function testFail_lastUpdateTime_value_invalid() public {
        overlay.modifyParameters("lastUpdateTime", now - 1);
    }
    function test_set_lastUpdateTime() public {
        overlay.modifyParameters("lastUpdateTime", now + 1);
        assertEq(adjuster.lastUpdateTime(), now + 1);
    }
}
