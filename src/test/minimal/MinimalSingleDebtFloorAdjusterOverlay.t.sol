pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalSingleDebtFloorAdjusterOverlay} from "../../overlays/minimal/MinimalSingleDebtFloorAdjusterOverlay.sol";

contract User {
    function doModifyParameters(MinimalSingleDebtFloorAdjusterOverlay overlay, bytes32 parameter, uint256 data) public {
        overlay.modifyParameters(parameter, data);
    }

    function doModifyParameters(MinimalSingleDebtFloorAdjusterOverlay overlay, bytes32 parameter, address data) public {
        overlay.modifyParameters(parameter, data);
    }
}
contract SingleDebtFloorAdjuster {
    uint256 public lastUpdateTime;
    uint256 public maxPriceDeviation;
    uint256 public auctionDiscount;
    address public gasPriceOracle;
    address public ethPriceOracle;

    function modifyParameters(bytes32 parameter, uint256 data) public {
        if (parameter == "lastUpdateTime") lastUpdateTime = data;
        if (parameter == "maxPriceDeviation") maxPriceDeviation = data;
        if (parameter == "auctionDiscount") auctionDiscount = data;
    }

    function modifyParameters(bytes32 parameter, address data) public {
        if (parameter == "gasPriceOracle") gasPriceOracle = data;
        if (parameter == "ethPriceOracle") ethPriceOracle = data;
    }
}
abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract MinimalSingleDebtFloorAdjusterOverlayTest is DSTest {
    Hevm hevm;

    User user;
    SingleDebtFloorAdjuster adjuster;
    MinimalSingleDebtFloorAdjusterOverlay overlay;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        user     = new User();
        adjuster = new SingleDebtFloorAdjuster();
        overlay  = new MinimalSingleDebtFloorAdjusterOverlay(address(adjuster));
    }

    function test_setup() public {
        assertEq(address(overlay.adjuster()), address(adjuster));
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
    function testFail_set_uint_unauthed() public {
        user.doModifyParameters(overlay, "lastUpdateTime", now + 1);
    }
    function testFail_set_random_var_uint() public {
        overlay.modifyParameters("randomVar", 10);
    }
    function testFail_lastUpdateTime_value_invalid() public {
        overlay.modifyParameters("lastUpdateTime", now - 1);
    }
    function test_set_lastUpdateTime() public {
        overlay.modifyParameters("lastUpdateTime", now + 1);
        assertEq(adjuster.lastUpdateTime(), now + 1);
    }
    function test_set_maxPriceDeviation() public {
        overlay.modifyParameters("maxPriceDeviation", 10**27);
        assertEq(adjuster.maxPriceDeviation(), 10**27);
    }
    function test_set_auctionDiscount() public {
        overlay.modifyParameters("auctionDiscount", 70000000000000000);
        assertEq(adjuster.auctionDiscount(), 70000000000000000);
    }
    function testFail_set_address_unauthed() public {
        user.doModifyParameters(overlay, "ethPriceOracle", address(1));
    }
    function testFail_set_random_var_address() public {
        overlay.modifyParameters("randomVar", address(1));
    }
    function test_set_ethPriceOracle() public {
        overlay.modifyParameters("ethPriceOracle", address(2));
        assertEq(adjuster.ethPriceOracle(), address(2));
    }
    function test_set_gasPriceOracle() public {
        overlay.modifyParameters("gasPriceOracle", address(3));
        assertEq(adjuster.gasPriceOracle(), address(3));
    }
}
