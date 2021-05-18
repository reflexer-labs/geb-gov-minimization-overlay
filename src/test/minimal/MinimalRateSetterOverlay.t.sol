pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../../overlays/minimal/MinimalRateSetterOverlay.sol";

contract User {
    function doModifyParameters(MinimalRateSetterOverlay overlay, bytes32 parameter, address addr) public {
        overlay.modifyParameters(parameter, addr);
    }
}
contract RateSetter {
    address public orcl;

    function modifyParameters(bytes32 parameter, address addr) external {
        if (parameter == "orcl") orcl = addr;
    }
}

contract MinimalRateSetterOverlayTest is DSTest {
    User user;
    MinimalRateSetterOverlay overlay;
    RateSetter rateSetter;

    address pCalculator  = address(0x1);
    address piCalculator = address(0x2);

    function setUp() public {
        user = new User();
        rateSetter = new RateSetter();
        overlay = new MinimalRateSetterOverlay(address(rateSetter), pCalculator, piCalculator);
    }

    function test_setup() public {
        assertEq(address(overlay.rateSetter()), address(rateSetter));
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
    function test_set_orcl() public {
        overlay.modifyParameters("orcl", address(0x1));
        assertEq(address(rateSetter.orcl()), address(0x1));
    }
    function testFail_set_orcl_unauthed() public {
        user.doModifyParameters(overlay, "orcl", address(0x1));
    }
    function testFail_set_another_param() public {
        overlay.modifyParameters("oracleRelayer", address(0x1));
    }
}
