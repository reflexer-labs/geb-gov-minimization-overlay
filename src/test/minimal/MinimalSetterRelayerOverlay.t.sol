pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../../overlays/minimal/MinimalSetterRelayerOverlay.sol";

contract User {
    function doModifyParameters(MinimalSetterRelayerOverlay overlay, bytes32 parameter, address addr) public {
        overlay.modifyParameters(parameter, addr);
    }
}
contract SetterRelayer {
    address public setter;

    function modifyParameters(bytes32 parameter, address addr) external {
        if (parameter == "setter") setter = addr;
    }
}

contract MinimalSetterRelayerOverlayTest is DSTest {
    User user;
    MinimalSetterRelayerOverlay overlay;
    SetterRelayer relayer;

    function setUp() public {
        user = new User();
        relayer = new SetterRelayer();
        overlay = new MinimalSetterRelayerOverlay(address(relayer));
    }

    function test_setup() public {
        assertEq(address(overlay.relayer()), address(relayer));
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
    function test_set_setter() public {
        overlay.modifyParameters("setter", address(0x1));
        assertEq(address(relayer.setter()), address(0x1));
    }
    function testFail_set_setter_unauthed() public {
        user.doModifyParameters(overlay, "setter", address(0x1));
    }
    function testFail_set_another_param() public {
        overlay.modifyParameters("treasury", address(0x1));
    }
}
