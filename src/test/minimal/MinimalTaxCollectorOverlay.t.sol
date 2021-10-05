pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/single/TaxCollector.sol";
import "geb/single/SAFEEngine.sol";

import "../../overlays/minimal/MinimalTaxCollectorOverlay.sol";

contract User {
    function doModifyParameters(
      MinimalTaxCollectorOverlay overlay,
      bytes32 collateralType,
      bytes32 parameter,
      uint256 data
    ) external {
      overlay.modifyParameters(collateralType, parameter, data);
    }
}

contract MinimalTaxCollectorOverlayTest is DSTest {
    User user;
    TaxCollector taxCollector;
    SAFEEngine safeEngine;
    MinimalTaxCollectorOverlay overlay;

    // Vars
    uint256 constant RAY       = 10 ** 27;

    bytes32[] collateralTypes = [bytes32("ETH-A"), bytes32("ETH-B")];
    uint256[] lowerBounds     = [RAY + 1, RAY + 20];
    uint256[] upperBounds     = [RAY + 5, RAY + 100];

    function setUp() public {
        user = new User();
        safeEngine = new SAFEEngine();
        taxCollector = new TaxCollector(address(safeEngine));
        overlay = new MinimalTaxCollectorOverlay(
          address(taxCollector),
          collateralTypes,
          lowerBounds,
          upperBounds
        );

        taxCollector.initializeCollateralType("ETH-A");
        taxCollector.initializeCollateralType("ETH-B");

        taxCollector.addAuthorization(address(overlay));
    }

    function test_setup() public {
        assertEq(address(overlay.taxCollector()), address(taxCollector));
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
    function test_set_sf_first_collateral() public {
        overlay.modifyParameters("ETH-A", "stabilityFee", RAY + 4);
        (uint256 stabilityFee, ) = taxCollector.collateralTypes("ETH-A");
        assertEq(stabilityFee, RAY + 4);
    }
    function test_set_sf_second_collateral() public {
        overlay.modifyParameters("ETH-B", "stabilityFee", RAY + 80);
        (uint256 stabilityFee, ) = taxCollector.collateralTypes("ETH-B");
        assertEq(stabilityFee, RAY + 80);
    }
    function testFail_set_sf_by_unauthed() public {
        user.doModifyParameters(
          overlay,
          "ETH-A",
          "stabilityFee",
          RAY + 4
        );
    }
    function testFail_set_sf_above_upper_limit() public {
        overlay.modifyParameters("ETH-B", "stabilityFee", RAY + 200);
    }
    function testFail_set_sf_below_lower_limit() public {
        overlay.modifyParameters("ETH-A", "stabilityFee", RAY);
    }
}
