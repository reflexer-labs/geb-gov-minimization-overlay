pragma solidity 0.6.7;

import "ds-test/test.sol";

import {DebtCeilingSetterOverlay} from "../overlays/DebtCeilingSetterOverlay.sol";

contract User {
    function doModifyParameters(DebtCeilingSetterOverlay overlay, bytes32 parameter, uint256 val) public {
        overlay.modifyParameters(parameter, val);
    }
}
contract DebtCeilingSetter {
    uint256 public blockIncreaseWhenRevalue;
    uint256 public blockDecreaseWhenDevalue;

    function modifyParameters(bytes32 parameter, uint256 val) public {
        if (parameter == "blockIncreaseWhenRevalue") blockIncreaseWhenRevalue = val;
        else if (parameter == "blockDecreaseWhenDevalue") blockDecreaseWhenDevalue = val;
    }
}

contract DebtCeilingSetterOverlayTest is DSTest {
    User user;
    DebtCeilingSetter setter;
    DebtCeilingSetterOverlay overlay;

    function setUp() public {
        user     = new User();
        setter   = new DebtCeilingSetter();
        overlay  = new DebtCeilingSetterOverlay(address(setter));
    }

    function test_setup() public {
        assertEq(address(overlay.ceilingSetter()), address(setter));
    }
    function test_set_block_increase() public {
        overlay.modifyParameters("blockIncreaseWhenRevalue", 1);
        assertEq(setter.blockIncreaseWhenRevalue(), 1);
    }
    function test_set_block_decrease() public {
        overlay.modifyParameters("blockDecreaseWhenDevalue", 1);
        assertEq(setter.blockDecreaseWhenDevalue(), 1);
    }
    function testFail_set_block_increase_by_unauthed() public {
        user.doModifyParameters(overlay, "blockIncreaseWhenRevalue", 1);
    }
    function testFail_set_other_param() public {
        overlay.modifyParameters("maxRewardIncreaseDelay", 2);
    }
}
