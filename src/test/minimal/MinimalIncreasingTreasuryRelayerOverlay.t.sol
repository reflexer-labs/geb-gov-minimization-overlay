pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalIncreasingTreasuryRelayerOverlay} from "../../overlays/minimal/MinimalIncreasingTreasuryRelayerOverlay.sol";

contract User {
    function doToggleRelayer(MinimalIncreasingTreasuryRelayerOverlay overlay, address relayer) public {
        overlay.toggleRelayer(relayer);
    }
    function doModifyParameters(
      MinimalIncreasingTreasuryRelayerOverlay overlay, address relayer, bytes32 parameter, address data
    ) public {
        overlay.modifyParameters(relayer, parameter, data);
    }
}
contract IncreasingTreasuryRelayer {
    address public refundRequestor;

    function modifyParameters(bytes32 parameter, address data) public {
        if (parameter == "refundRequestor") refundRequestor = data;
    }
}

contract MinimalIncreasingTreasuryRelayerOverlayTest is DSTest {
    User user;
    IncreasingTreasuryRelayer relayer;
    MinimalIncreasingTreasuryRelayerOverlay overlay;

    address alice = address(0x123);

    function setUp() public {
        user       = new User();
        relayer = new IncreasingTreasuryRelayer();
        overlay    = new MinimalIncreasingTreasuryRelayerOverlay();
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
    function testFail_toggleRelayer_invalid_caller() public {
        user.doToggleRelayer(overlay, address(relayer));
    }
    function test_toggleRelayer() public {
        overlay.toggleRelayer(address(relayer));
        assertEq(overlay.relayers(address(relayer)), 1);
        overlay.toggleRelayer(address(relayer));
        assertEq(overlay.relayers(address(relayer)), 0);
    }
    function testFail_modifyParameters_invalid_caller() public {
        overlay.toggleRelayer(address(relayer));
        user.doModifyParameters(overlay, address(relayer), "refundRequestor", alice);
    }
    function testFail_modifyParameters_invalid_relayer() public {
        overlay.modifyParameters(address(relayer), "refundRequestor", alice);
    }
    function testFail_modifyParameters_random_variable() public {
        overlay.toggleRelayer(address(relayer));
        overlay.modifyParameters(address(relayer), "random", alice);
    }
    function test_modify_parameters() public {
        overlay.toggleRelayer(address(relayer));
        overlay.modifyParameters(address(relayer), "refundRequestor", alice);

        assertEq(relayer.refundRequestor(), alice);
    }
}
