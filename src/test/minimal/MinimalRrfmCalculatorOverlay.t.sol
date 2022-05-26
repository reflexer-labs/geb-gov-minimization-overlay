pragma solidity 0.6.7;

import "ds-test/test.sol";

import "../../overlays/minimal/MinimalRrfmCalculatorOverlay.sol";

contract User {
    function doModifyParameters(MinimalRrfmCalculatorOverlay overlay, bytes32 parameter, uint256 val) external {
        overlay.modifyParameters(parameter, val);
    }
    function doModifyParameters(MinimalRrfmCalculatorOverlay overlay, bytes32 parameter, int256 val) external {
        overlay.modifyParameters(parameter, val);
    }
}
contract Calculator {
    int256 public ag;
    int256 public sg;
    int256 public pdc;

    uint256 public allReaderToggle;
    uint256 public pscl;

    function modifyParameters(bytes32 parameter, uint256 val) external {
        if (parameter == "allReaderToggle") {
           allReaderToggle = val;
        }
        else if (parameter == "pscl") {
            pscl = val;
        }
        else revert();
    }
    function modifyParameters(bytes32 parameter, int256 val) external {
        if (parameter == "ag") {
            ag = val;
        }
        else if (parameter == "sg") {
            sg = val;
        }
        else if (parameter == "pdc") {
            pdc = val;
        }
        else revert();
    }
}

contract MinimalRrfmCalculatorOverlayTest is DSTest {
    User user;
    Calculator calculator;
    MinimalRrfmCalculatorOverlay overlay;

    // Constants
    uint256 WAD = 10 ** 18;
    uint256 RAY = 10 ** 27;

    // Init params
    bytes32[] unsignedParams      = [bytes32("allReaderToggle"), bytes32("pscl")];
    bytes32[] signedParams        = [bytes32("ag"), bytes32("sg")];
    uint256[] unsignedUpperBounds = [uint(1), WAD + 10];
    uint256[] unsignedLowerBounds = [uint(1), WAD - 5];
    int256[] signedUpperBounds    = [int(WAD * 5), int(WAD * 10)];
    int256[] signedLowerBounds    = [int(WAD / 5), int(WAD / 10)];

    function setUp() public {
        user = new User();
        calculator = new Calculator();

        overlay = new MinimalRrfmCalculatorOverlay(
            address(calculator),
            unsignedParams,
            signedParams,
            unsignedUpperBounds,
            unsignedLowerBounds,
            signedUpperBounds,
            signedLowerBounds
        );
    }

    function test_setup() public {
        assertEq(address(overlay.calculator()), address(calculator));

        (int256 upperBound, int256 lowerBound) = overlay.signedBounds(bytes32("ag"));
        assertEq(upperBound, int(WAD * 5));
        assertEq(lowerBound, int(WAD / 5));

        (upperBound, lowerBound) = overlay.signedBounds(bytes32("sg"));
        assertEq(upperBound, int(WAD * 10));
        assertEq(lowerBound, int(WAD / 10));

        (uint256 unsignedUpperBound, uint256 unsignedLowerBound) = overlay.unsignedBounds(bytes32("allReaderToggle"));
        assertEq(unsignedUpperBound, uint(1));
        assertEq(unsignedLowerBound, uint(1));

        (unsignedUpperBound, unsignedLowerBound) = overlay.unsignedBounds(bytes32("pscl"));
        assertEq(unsignedUpperBound, uint(WAD + 10));
        assertEq(unsignedLowerBound, uint(WAD - 5));
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
    function test_set_allReaderToggle() public {
        assertEq(calculator.allReaderToggle(), uint(0));
        overlay.modifyParameters("allReaderToggle", uint(1000));
        assertEq(calculator.allReaderToggle(), uint(1));
    }
    function test_set_pscl() public {
        assertEq(calculator.pscl(), uint(0));
        overlay.modifyParameters("pscl", uint(WAD + 9));
        assertEq(calculator.pscl(), uint(WAD + 9));
    }
    function test_set_ag() public {
        assertEq(calculator.ag(), int(0));
        overlay.modifyParameters("ag", int(WAD / 2));
        assertEq(calculator.ag(), int(WAD / 2));
    }
    function test_set_sg() public {
        assertEq(calculator.sg(), int(0));
        overlay.modifyParameters("sg", int(WAD / 6));
        assertEq(calculator.sg(), int(WAD / 6));
    }
    function test_set_pdc() public {
        calculator.modifyParameters("pdc", int(100));
        overlay.modifyParameters("pdc", int(RAY * WAD));
        assertEq(calculator.pdc(), int(0));
    }
    function testFail_set_pscl_exceed_upper_bound() public {
        overlay.modifyParameters("pscl", uint(WAD * 9));
    }
    function testFail_set_pscl_exceed_lower_bound() public {
        overlay.modifyParameters("pscl", uint(WAD / 9));
    }
    function testFail_set_ag_exceed_upper_bound() public {
        overlay.modifyParameters("ag", int(WAD * RAY + 1));
    }
    function testFail_set_ag_exceed_lower_bound() public {
        overlay.modifyParameters("ag", int(0));
    }
    function testFail_set_uint_unauthed() public {
        user.doModifyParameters(overlay, "noise", uint(WAD + 9));
    }
    function testFail_set_int_unauthed() public {
        user.doModifyParameters(overlay, "pep", int(WAD / 6));
    }
}
