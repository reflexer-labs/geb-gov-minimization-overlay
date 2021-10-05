pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/single/SAFEEngine.sol";

import "../../overlays/partial/PartialSAFEEngineOverlay.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract User {
    function addCollateralJoin(PartialSAFEEngineOverlay overlay, address join) external {
        overlay.addCollateralJoin(join);
    }
    function removeCollateralJoin(PartialSAFEEngineOverlay overlay, address join) external {
        overlay.removeCollateralJoin(join);
    }
    function initializeCollateralType(PartialSAFEEngineOverlay overlay, bytes32 collateralType) external {
        overlay.initializeCollateralType(collateralType);
    }
    function modifyParameters(PartialSAFEEngineOverlay overlay, bytes32 parameter, uint256 val) external {
        overlay.modifyParameters(parameter, val);
    }
    function modifyParameters(PartialSAFEEngineOverlay overlay, bytes32 collateralType, bytes32 parameter, uint256 val) external {
        overlay.modifyParameters(collateralType, parameter, val);
    }
    function modifyCollateralBalance(PartialSAFEEngineOverlay overlay, bytes32 collateralType, address account, int256 wad) external {
        overlay.modifyCollateralBalance(collateralType, account, wad);
    }
    function createUnbackedDebt(PartialSAFEEngineOverlay overlay, address debtDestination, address coinDestination, uint256 rad) external {
        overlay.createUnbackedDebt(debtDestination, coinDestination, rad);
    }
}

contract PartialSAFEEngineOverlayTest is DSTest {
    Hevm hevm;

    User malicious;
    User benevolent;

    SAFEEngine safeEngine;

    PartialSAFEEngineOverlay overlay;

    User user;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        safeEngine = new SAFEEngine();

        overlay = new PartialSAFEEngineOverlay(address(safeEngine));
        safeEngine.addAuthorization(address(overlay));

        user = new User();
    }

    function test_setup() public {
        assertEq(address(overlay.safeEngine()), address(safeEngine));
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
    function test_add_collateralJoin() public {
        assertEq(overlay.collateralJoins(address(this)), 0);
        overlay.addCollateralJoin(address(this));
        assertEq(overlay.collateralJoins(address(this)), 1);
    }
    function testFail_add_collateralJoin_unauthed() public {
        user.addCollateralJoin(overlay, address(this));
    }
    function test_remove_collateralJoin() public {
        overlay.addCollateralJoin(address(this));
        overlay.removeCollateralJoin(address(this));
        assertEq(overlay.collateralJoins(address(this)), 0);
    }
    function testFail_remove_collateralJoin_unauthed() public {
        overlay.addCollateralJoin(address(this));
        user.removeCollateralJoin(overlay, address(this));
    }
    function test_initializeCollateralType() public {
        overlay.initializeCollateralType("ETH-A");
        (, uint accumulatedRate, , , , ) = safeEngine.collateralTypes("ETH-A");
        assertEq(accumulatedRate, 1E27);
    }
    function testFail_initializeCollateralType_unauthed() public {
        user.initializeCollateralType(overlay, "ETH-A");
    }
    function test_modifyParam_uint() public {
        overlay.modifyParameters("globalDebtCeiling", 50);
        assertEq(safeEngine.globalDebtCeiling(), 50);
    }
    function testFail_modifyParam_uint_unauthed() public {
        user.modifyParameters(overlay, "globalDebtCeiling", 50);
    }
    function test_modifyParam_collateral_uint() public {
        overlay.initializeCollateralType("ETH-A");
        overlay.modifyParameters("ETH-A", "debtFloor", 100E45);

        (, , , , uint256 debtFloor, ) = safeEngine.collateralTypes("ETH-A");
        assertEq(debtFloor, 100E45);
    }
    function testFail_modifyParam_collateral_uint_unauthed() public {
        overlay.initializeCollateralType("ETH-A");
        user.modifyParameters(overlay, "ETH-A", "debtFloor", 100E45);
    }
    function test_modifyParam_collateral_amount_int() public {
        overlay.addCollateralJoin(address(this));
        overlay.modifyCollateralBalance("ETH-A", address(this), 1E18);
        assertEq(safeEngine.tokenCollateral("ETH-A", address(this)), 1E18);
    }
    function testFail_modifyParam_collateral_int_unauthed() public {
        user.modifyCollateralBalance(overlay, "ETH-A", address(this), 1E18);
    }
    function test_createUnbackedDebt() public {
        overlay.createUnbackedDebt(address(0x1), address(this), 50E45);
        assertEq(safeEngine.coinBalance(address(this)), 50E45);
        assertEq(safeEngine.debtBalance(address(0x1)), 50E45);
    }
    function testFail_createUnbackedDebt_unauthed() public {
        user.createUnbackedDebt(overlay, address(0x1), address(this), 50E45);
    }
}
