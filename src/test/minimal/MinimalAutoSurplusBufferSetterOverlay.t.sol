pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalAutoSurplusBufferSetterOverlay} from "../../overlays/minimal/MinimalAutoSurplusBufferSetterOverlay.sol";

contract User {
    function doModifyParameters(MinimalAutoSurplusBufferSetterOverlay overlay, bytes32 parameter, uint256 data) public {
        overlay.modifyParameters(parameter, data);
    }
}
contract AutoSurplusBufferSetter {
    uint256 public stopAdjustments;

    function modifyParameters(bytes32 parameter, uint256 data) public {
        if (parameter == "stopAdjustments") stopAdjustments = data;
    }
}

contract MinimalAutoSurplusBufferSetterOverlayTest is DSTest {
    User user;
    AutoSurplusBufferSetter setter;
    MinimalAutoSurplusBufferSetterOverlay overlay;

    function setUp() public {
        user     = new User();
        setter   = new AutoSurplusBufferSetter();
        overlay  = new MinimalAutoSurplusBufferSetterOverlay(address(setter));
    }

    function test_setup() public {
        assertEq(address(overlay.autoSurplusBuffer()), address(setter));
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
    function testFail_set_stopAdjustments_unauthed() public {
        user.doModifyParameters(overlay, "stopAdjustments", 1);
    }
    function testFail_set_random_var() public {
        overlay.modifyParameters("randomVar", 1);
    }
    function test_set_stopAdjustments() public {
        overlay.modifyParameters("stopAdjustments", 1);
        assertEq(setter.stopAdjustments(), 1);
    }
}
