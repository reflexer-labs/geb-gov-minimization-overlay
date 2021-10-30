pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalSFTreasuryCoreParamAdjusterOverlay} from "../../overlays/minimal/MinimalSFTreasuryCoreParamAdjusterOverlay.sol";

contract User {
    function doModifyParameters(MinimalSFTreasuryCoreParamAdjusterOverlay overlay, bytes32 parameter, uint256 data) public {
        overlay.modifyParameters(parameter, data);
    }

    function doModifyParameters(
        MinimalSFTreasuryCoreParamAdjusterOverlay overlay,
        address receiver,
        bytes4 targetFunction,
        bytes32 parameter,
        uint256 data) public
    {
        overlay.modifyParameters(receiver, targetFunction, parameter, data);
    }
}
contract SFTreasuryCoreParamAdjuster {
    uint256 public minPullFundsThreshold;
    mapping (address => mapping(bytes4 => uint)) public latestExpectedCalls;

    function modifyParameters(bytes32 parameter, uint256 data) external {
        if (parameter == "minPullFundsThreshold") minPullFundsThreshold = data;
    }
    function modifyParameters(address receiver, bytes4 targetFunction, bytes32 parameter, uint256 val) external {
        if (parameter == "latestExpectedCalls") latestExpectedCalls[receiver][targetFunction] = val;
    }
}

contract MinimalRewardsAdjusterOverlayTest is DSTest {
    User user;
    SFTreasuryCoreParamAdjuster adjuster;
    MinimalSFTreasuryCoreParamAdjusterOverlay overlay;

    function setUp() public {
        user     = new User();
        adjuster = new SFTreasuryCoreParamAdjuster();
        overlay  = new MinimalSFTreasuryCoreParamAdjusterOverlay(address(adjuster));
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
    function testFail_set_minPullFundsThreshold_unauthed() public {
        user.doModifyParameters(overlay, "minPullFundsThreshold", 1);
    }
    function testFail_set_random_var() public {
        overlay.modifyParameters("randomVar", 1);
    }
    function test_set_minPullFundsThreshold() public {
        overlay.modifyParameters("minPullFundsThreshold", 8);
        assertEq(adjuster.minPullFundsThreshold(), 8);
    }
    function testFail_set_updateDelay_unauthed() public {
        user.doModifyParameters(overlay, address(0x1), bytes4("0x5"), "updateDelay", 1);
    }
    function testFail_set_random_var2() public {
        overlay.modifyParameters(address(0x1), bytes4("0x5"), "randomVar", 1);
    }
    function test_set_updateDelay() public {
        overlay.modifyParameters(address(0x1), bytes4("0x5"), "latestExpectedCalls", 420);
        assertEq(adjuster.latestExpectedCalls(address(0x1), bytes4("0x5")), 420);
    }
}
