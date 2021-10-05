pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalFixedTreasuryReimbursementOverlay} from "../../overlays/minimal/MinimalFixedTreasuryReimbursementOverlay.sol";

contract User {
    function doModifyParameters(MinimalFixedTreasuryReimbursementOverlay overlay, bytes32 parameter, uint256 data) public {
        overlay.modifyParameters(parameter, data);
    }
}
contract FixedTreasuryReimbursement {
    uint256 public fixedReward;

    function modifyParameters(bytes32 parameter, uint256 data) public {
        if (parameter == "fixedReward") fixedReward = data;
    }
}

contract MinimalFixedTreasuryReimbursementOverlayTest is DSTest {
    User user;
    FixedTreasuryReimbursement setter;
    MinimalFixedTreasuryReimbursementOverlay overlay;

    function setUp() public {
        user     = new User();
        setter   = new FixedTreasuryReimbursement();
        overlay  = new MinimalFixedTreasuryReimbursementOverlay(address(setter));
    }

    function test_setup() public {
        assertEq(address(overlay.reimburser()), address(setter));
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
    function testFail_set_fixedReward_unauthed() public {
        user.doModifyParameters(overlay, "fixedReward", 10);
    }
    function testFail_set_random_var() public {
        overlay.modifyParameters("randomVar", 10);
    }
    function test_set_fixedReward() public {
        overlay.modifyParameters("fixedReward", 10);
        assertEq(setter.fixedReward(), 10);
    }
}
