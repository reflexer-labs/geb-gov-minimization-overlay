pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalRewardsAdjusterOverlay} from "../../overlays/minimal/MinimalRewardsAdjusterOverlay.sol";

contract User {
    function doModifyParameters(MinimalRewardsAdjusterOverlay overlay, bytes32 parameter, address data) public {
        overlay.modifyParameters(parameter, data);
    }

    function doModifyParameters(
        MinimalRewardsAdjusterOverlay overlay,
        address receiver,
        bytes4 targetFunction,
        bytes32 parameter,
        uint256 data) public
    {
        overlay.modifyParameters(receiver, targetFunction, parameter, data);
    }
}
contract RewardsAdjuster {
    address public gasPriceOracle;
    mapping (address => mapping(bytes4 => uint)) public updateDelays;

    function modifyParameters(bytes32 parameter, address data) external {
        if (parameter == "gasPriceOracle") gasPriceOracle = data;
    }
    function modifyParameters(address receiver, bytes4 targetFunction, bytes32 parameter, uint256 val) external {
        if (parameter == "updateDelay") updateDelays[receiver][targetFunction] = val;
    }
}

contract MinimalRewardsAdjusterOverlayTest is DSTest {
    User user;
    RewardsAdjuster adjuster;
    MinimalRewardsAdjusterOverlay overlay;

    function setUp() public {
        user     = new User();
        adjuster = new RewardsAdjuster();
        overlay  = new MinimalRewardsAdjusterOverlay(address(adjuster));
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
    function testFail_set_gasPriceOracle_unauthed() public {
        user.doModifyParameters(overlay, "gasPriceOracle", address(1));
    }
    function testFail_set_random_var() public {
        overlay.modifyParameters("randomVar", address(1));
    }
    function test_set_gasPriceOracle() public {
        overlay.modifyParameters("gasPriceOracle", address(8));
        assertEq(adjuster.gasPriceOracle(), address(8));
    }
    function testFail_set_updateDelay_unauthed() public {
        user.doModifyParameters(overlay, address(0x1), bytes4("0x5"), "updateDelay", 1);
    }
    function testFail_set_random_var2() public {
        overlay.modifyParameters(address(0x1), bytes4("0x5"), "randomVar", 1);
    }
    function test_set_updateDelay() public {
        overlay.modifyParameters(address(0x1), bytes4("0x5"), "updateDelay", 420);
        assertEq(adjuster.updateDelays(address(0x1), bytes4("0x5")), 420);
    }
}
