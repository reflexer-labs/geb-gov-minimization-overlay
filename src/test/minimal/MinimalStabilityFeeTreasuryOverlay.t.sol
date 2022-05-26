pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../../overlays/minimal/MinimalStabilityFeeTreasuryOverlay.sol";

contract User {
    function doSetTotalAllowance(MinimalStabilityFeeTreasuryOverlay overlay, address dst, uint256 amount) external {
        overlay.setTotalAllowance(dst, amount);
    }
    function doSetPerBlocklAllowance(MinimalStabilityFeeTreasuryOverlay overlay, address dst, uint256 amount) external {
        overlay.setPerBlockAllowance(dst, amount);
    }
    function doModifyParameters(MinimalStabilityFeeTreasuryOverlay overlay, bytes32 param, uint256 val) external {
        overlay.modifyParameters(param, val);
    }
}
contract StabilityFeeTreasury {
    mapping (bytes32 => uint256) public params;
    function setTotalAllowance(address dst, uint256 amount) external {
        return;
    }
    function setPerBlockAllowance(address dst, uint256 amount) external {
        return;
    }
    function modifyParameters(bytes32 param, uint256 val) external {
        params[param] = val;
    }
}

contract MinimalStabilityFeeTreasuryOverlayTest is DSTest {
    User user;
    StabilityFeeTreasury treasury;
    MinimalStabilityFeeTreasuryOverlay overlay;

    function setUp() public {
        user     = new User();
        treasury = new StabilityFeeTreasury();
        overlay  = new MinimalStabilityFeeTreasuryOverlay(address(treasury));
    }

    function test_setup() public {
        assertEq(address(overlay.treasury()), address(treasury));
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
    function test_set_total_allowance() public {
        overlay.setTotalAllowance(address(0x1), 1 ether);
    }
    function testFail_set_total_allowance_unauthed() public {
        user.doSetTotalAllowance(overlay, address(0x1), 1 ether);
    }
    function test_set_per_block_allowance() public {
        overlay.setPerBlockAllowance(address(0x1), 2 ether);
    }
    function testFail_set_per_block_allowance_unauthed() public {
        user.doSetPerBlocklAllowance(overlay, address(0x1), 2 ether);
    }
    function test_modify_parameters(bytes32 param, uint256 val) public {
        overlay.modifyParameters(param, val);
        assertEq(treasury.params(param), val);
    }
    function testFail_modify_parameters_unauthed() public {
        user.doModifyParameters(overlay, bytes32("0x0"), 2 ether);
    }
}
