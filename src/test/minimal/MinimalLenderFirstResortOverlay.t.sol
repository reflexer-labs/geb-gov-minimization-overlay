pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalLenderFirstResortOverlay} from "../../overlays/minimal/MinimalLenderFirstResortOverlay.sol";

contract User {
    function doModifyParameters(MinimalLenderFirstResortOverlay overlay, bytes32 parameter, uint256 data) public {
        overlay.modifyParameters(parameter, data);
    }
}
contract LenderFirstResort {
    uint256 public escrowPaused;

    function modifyParameters(bytes32 parameter, uint256 data) public {
        if (parameter == "escrowPaused") escrowPaused = data;
    }
}

contract MinimalLenderFirstResortOverlayTest is DSTest {
    User user;
    LenderFirstResort staking;
    MinimalLenderFirstResortOverlay overlay;

    function setUp() public {
        user     = new User();
        staking  = new LenderFirstResort();
        overlay  = new MinimalLenderFirstResortOverlay(address(staking), 100 ether);
    }

    function test_setup() public {
        assertEq(address(overlay.staking()), address(staking));
        assertEq(overlay.maxStakedTokensToKeep(), 100 ether);
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
    function testFail_set_escrowPaused_unauthed() public {
        user.doModifyParameters(overlay, "escrowPaused", 1);
    }
    function testFail_set_random_var() public {
        overlay.modifyParameters("randomVar", 1);
    }
    function test_set_escrowPaused() public {
        overlay.modifyParameters("escrowPaused", 1);
        assertEq(staking.escrowPaused(), 1);
    }
}
