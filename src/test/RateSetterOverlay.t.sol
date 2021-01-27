pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../overlays/RateSetterOverlay.sol";

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
