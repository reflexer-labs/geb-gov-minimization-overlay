pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalIncreasingTreasuryReimbursementOverlay} from "../../overlays/minimal/MinimalIncreasingTreasuryReimbursementOverlay.sol";

contract User {
    function doToggleReimburser(MinimalIncreasingTreasuryReimbursementOverlay overlay, address reimburser) public {
        overlay.toggleReimburser(reimburser);
    }
    function doModifyParameters(
      MinimalIncreasingTreasuryReimbursementOverlay overlay, address reimburser, bytes32 parameter, uint256 data
    ) public {
        overlay.modifyParameters(reimburser, parameter, data);
    }
}
contract IncreasingTreasuryReimbursement {
    uint256 public baseUpdateCallerReward;
    uint256 public maxUpdateCallerReward;

    function modifyParameters(bytes32 parameter, uint256 data) public {
        if (parameter == "baseUpdateCallerReward") baseUpdateCallerReward = data;
        else if (parameter == "maxUpdateCallerReward") maxUpdateCallerReward = data;
    }
}

contract MinimalIncreasingTreasuryReimbursementOverlayTest is DSTest {
    User user;
    IncreasingTreasuryReimbursement reimburser;
    MinimalIncreasingTreasuryReimbursementOverlay overlay;

    function setUp() public {
        user       = new User();
        reimburser = new IncreasingTreasuryReimbursement();
        overlay    = new MinimalIncreasingTreasuryReimbursementOverlay();
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
    function testFail_toggleReimburser_invalid_caller() public {
        user.doToggleReimburser(overlay, address(reimburser));
    }
    function test_toggleReimburser() public {
        overlay.toggleReimburser(address(reimburser));
        assertEq(overlay.reimbursers(address(reimburser)), 1);
        overlay.toggleReimburser(address(reimburser));
        assertEq(overlay.reimbursers(address(reimburser)), 0);
    }
    function testFail_modifyParameters_invalid_caller() public {
        overlay.toggleReimburser(address(reimburser));
        user.doModifyParameters(overlay, address(reimburser), "baseUpdateCallerReward", 10);
    }
    function testFail_modifyParameters_invalid_reimburser() public {
        overlay.modifyParameters(address(reimburser), "baseUpdateCallerReward", 10);
    }
    function testFail_modifyParameters_random_variable() public {
        overlay.toggleReimburser(address(reimburser));
        overlay.modifyParameters(address(reimburser), "random", 10);
    }
    function test_modify_parameters() public {
        overlay.toggleReimburser(address(reimburser));
        overlay.modifyParameters(address(reimburser), "baseUpdateCallerReward", 10);
        overlay.modifyParameters(address(reimburser), "maxUpdateCallerReward", 20);

        assertEq(reimburser.baseUpdateCallerReward(), 10);
        assertEq(reimburser.maxUpdateCallerReward(), 20);
    }
}
