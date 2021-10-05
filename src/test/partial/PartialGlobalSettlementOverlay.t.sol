pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/GlobalSettlement.sol";

import "../../overlays/partial/PartialGlobalSettlementOverlay.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract User {
    function modifyParameters(PartialGlobalSettlementOverlay overlay, bytes32 parameter, uint256 val) external {
        overlay.modifyParameters(parameter, val);
    }
    function modifyParameters(PartialGlobalSettlementOverlay overlay, bytes32 parameter, address data) external {
        overlay.modifyParameters(parameter, data);
    }
    function shutdownSystem(PartialGlobalSettlementOverlay overlay) external {
        overlay.shutdownSystem();
    }
}

contract ShutdownableContract {
    function disableContract() public {}
}

contract PartialGlobalSettlementOverlayTest is DSTest {
    Hevm hevm;

    User user;

    GlobalSettlement globalSettlement;

    PartialGlobalSettlementOverlay overlay;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        globalSettlement = new GlobalSettlement();

        overlay = new PartialGlobalSettlementOverlay(address(globalSettlement));
        globalSettlement.addAuthorization(address(overlay));

        // Set up global settlement params
        globalSettlement.modifyParameters("safeEngine", address(new ShutdownableContract()));
        globalSettlement.modifyParameters("liquidationEngine", address(new ShutdownableContract()));
        globalSettlement.modifyParameters("accountingEngine", address(new ShutdownableContract()));
        globalSettlement.modifyParameters("oracleRelayer", address(new ShutdownableContract()));
        globalSettlement.modifyParameters("coinSavingsAccount", address(new ShutdownableContract()));
        globalSettlement.modifyParameters("stabilityFeeTreasury", address(new ShutdownableContract()));

        user = new User();
    }

    function test_setup() public {
        assertEq(address(overlay.globalSettlement()), address(globalSettlement));
        assertEq(overlay.authorizedAccounts(address(this)), 1);
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
    function test_modifyParam_address() public {
        overlay.modifyParameters("stabilityFeeTreasury", address(0x1));
        assertEq(address(globalSettlement.stabilityFeeTreasury()), address(0x1));
    }
    function testFail_modifyParam_forbidden_param() public {
        overlay.modifyParameters("liquidationEngine", address(0x1));
    }
    function testFail_modifyParam_address_unauthed() public {
        user.modifyParameters(overlay, "stabilityFeeTreasury", address(0x1));
    }
    function test_modifyParam_uint() public {
        overlay.modifyParameters("shutdownCooldown", 10 hours);
        assertEq(globalSettlement.shutdownCooldown(), 10 hours);
    }
    function testFail_modifyParam_uint_unauthed() public {
        user.modifyParameters(overlay, "shutdownCooldown", 10 hours);
    }
    function test_shutdown() public {
        assertEq(globalSettlement.shutdownTime(), 0);
        overlay.shutdownSystem();
        assertEq(globalSettlement.shutdownTime(), now);
    }
    function testFail_shutdown_unauthed() public {
        user.shutdownSystem(overlay);
    }
}
