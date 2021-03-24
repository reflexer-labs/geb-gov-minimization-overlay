pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../../overlays/minimal/RateSetterOverlay.sol";

contract User {
    function doModifyParameters(RateSetterOverlay overlay, bytes32 parameter, address addr) public {
        overlay.modifyParameters(parameter, addr);
    }
}
contract RateSetter {
    address public orcl;

    function modifyParameters(bytes32 parameter, address addr) external {
        if (parameter == "orcl") orcl = addr;
    }
}

contract RateSetterOverlayTest is DSTest {
    User user;
    RateSetterOverlay overlay;
    RateSetter rateSetter;

    function setUp() public {
        user = new User();
        rateSetter = new RateSetter();
        overlay = new RateSetterOverlay(address(rateSetter));
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
