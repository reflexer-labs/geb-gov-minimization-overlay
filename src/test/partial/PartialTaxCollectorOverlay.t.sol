pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/TaxCollector.sol";
import "geb/SAFEEngine.sol";

import "../../overlays/partial/PartialTaxCollectorOverlay.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract User {
    function initializeCollateralType(PartialTaxCollectorOverlay overlay, bytes32 collateralType) external {
        overlay.initializeCollateralType(collateralType);
    }
    function modifyParameters(PartialTaxCollectorOverlay overlay, bytes32 parameter, uint256 val) external {
        overlay.modifyParameters(parameter, val);
    }
    function modifyParameters(PartialTaxCollectorOverlay overlay, bytes32 collateralType, bytes32 parameter, uint256 val) external {
        overlay.modifyParameters(collateralType, parameter, val);
    }
    function modifyParameters(PartialTaxCollectorOverlay overlay, bytes32 collateralType, uint256 position, uint256 val) external {
        overlay.modifyParameters(collateralType, position, val);
    }
    function modifyParameters(PartialTaxCollectorOverlay overlay, bytes32 collateralType, uint256 position, uint256 taxPercentage, address receiverAccount) external {
        overlay.modifyParameters(collateralType, position, taxPercentage, receiverAccount);
    }
}

contract PartialAccountingEngineOverlayTest is DSTest {
    Hevm hevm;

    User user;

    TaxCollector taxCollector;
    SAFEEngine safeEngine;

    PartialTaxCollectorOverlay overlay;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        safeEngine = new SAFEEngine();
        taxCollector = new TaxCollector(address(safeEngine));

        overlay = new PartialTaxCollectorOverlay(address(taxCollector), taxCollector.WHOLE_TAX_CUT() / 3);
        taxCollector.addAuthorization(address(overlay));

        user = new User();
    }

    function test_setup() public {
        assertEq(address(overlay.taxCollector()), address(taxCollector));
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
    function test_initializeCollateralType() public {
        overlay.initializeCollateralType("ETH-A");
        (uint256 stabilityFee, ) = taxCollector.collateralTypes("ETH-A");
        assertEq(stabilityFee, 1E27);
    }
    function testFail_initializeCollateralType_unauthed() public {
        user.initializeCollateralType(overlay, "ETH-A");
    }
    function test_modifyParam_modifyParameters_collateral_uint() public {
        overlay.initializeCollateralType("ETH-A");
        overlay.modifyParameters("ETH-A", "stabilityFee", 1E27 + 1);

        (uint256 stabilityFee, ) = taxCollector.collateralTypes("ETH-A");
        assertEq(stabilityFee, 1E27 + 1);
    }
    function testFail_modifyParam_modifyParameters_collateral_uint() public {
        overlay.initializeCollateralType("ETH-A");
        user.modifyParameters(overlay, "ETH-A", "stabilityFee", 1E27 + 1);
    }
    function test_modifyParam_uint() public {
        overlay.modifyParameters("globalStabilityFee", 1E27 + 5);
        assertEq(taxCollector.globalStabilityFee(), 1E27 + 5);
    }
    function testFail_modifyParam_uint_unauthed() public {
        user.modifyParameters(overlay, "globalStabilityFee", 1E27 + 5);
    }
    function test_modifyParam_negative_tax() public {
        overlay.initializeCollateralType("ETH-A");
        overlay.modifyParameters("maxSecondaryReceivers", 1);
        overlay.modifyParameters("ETH-A", 10, taxCollector.WHOLE_TAX_CUT() / 10, address(0x1));
        overlay.modifyParameters("ETH-A", 1, 1);

        (uint canTakeBackTax, ) = taxCollector.secondaryTaxReceivers("ETH-A", 1);
        assertEq(canTakeBackTax, 1);
    }
    function testFail_modifyParam_negative_tax_unauthed() public {
        overlay.initializeCollateralType("ETH-A");
        overlay.modifyParameters("maxSecondaryReceivers", 1);
        overlay.modifyParameters("ETH-A", 10, taxCollector.WHOLE_TAX_CUT() / 10, address(0x1));
        user.modifyParameters(overlay, "ETH-A", 1, 1);
    }
    function test_modifyParam_secondary_tax() public {
        overlay.initializeCollateralType("ETH-A");
        overlay.modifyParameters("maxSecondaryReceivers", 1);
        overlay.modifyParameters("ETH-A", 10, taxCollector.WHOLE_TAX_CUT() / 10, address(0x1));

        assertEq(taxCollector.usedSecondaryReceiver(address(0x1)), 1);
    }
    function testFail_modifyParam_secondary_tax_above_threshold() public {
        overlay.initializeCollateralType("ETH-A");
        overlay.modifyParameters("maxSecondaryReceivers", 1);
        overlay.modifyParameters("ETH-A", 10, taxCollector.WHOLE_TAX_CUT() / 2, address(0x1));
    }
    function testFail_modifyParam_secondary_tax_unauthed() public {
        overlay.initializeCollateralType("ETH-A");
        overlay.modifyParameters("maxSecondaryReceivers", 1);
        user.modifyParameters(overlay, "ETH-A", 10, taxCollector.WHOLE_TAX_CUT() / 10, address(0x1));
    }
}
