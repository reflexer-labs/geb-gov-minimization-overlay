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
    int256 public pip;
    int256 public pep;
    int256 public pdc;

    uint256 public allReaderToggle;
    uint256 public noise;
    uint256 public defaultRedemptionRate;

    function modifyParameters(bytes32 parameter, uint256 val) external {
        if (parameter == "allReaderToggle") {
           allReaderToggle = val;
        }
        else if (parameter == "noise") {
            noise = val;
        }
        else if (parameter == "defaultRedemptionRate") {
            defaultRedemptionRate = val;
        }
        else revert();
    }
    function modifyParameters(bytes32 parameter, int256 val) external {
        if (parameter == "pip") {
            pip = val;
        }
        else if (parameter == "pep") {
            pep = val;
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
    bytes32[] unsignedParams      = [bytes32("allReaderToggle"), bytes32("noise"), bytes32("defaultRedemptionRate")];
    bytes32[] signedParams        = [bytes32("pip"), bytes32("pep")];
    uint256[] unsignedUpperBounds = [uint(1), WAD + 10, RAY + 5];
    uint256[] unsignedLowerBounds = [uint(1), WAD - 5, RAY - 10];
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

        (int256 upperBound, int256 lowerBound) = overlay.signedBounds(bytes32("pip"));
        assertEq(upperBound, int(WAD * 5));
        assertEq(lowerBound, int(WAD / 5));

        (upperBound, lowerBound) = overlay.signedBounds(bytes32("pep"));
        assertEq(upperBound, int(WAD * 10));
        assertEq(lowerBound, int(WAD / 10));

        (uint256 unsignedUpperBound, uint256 unsignedLowerBound) = overlay.unsignedBounds(bytes32("allReaderToggle"));
        assertEq(unsignedUpperBound, uint(1));
        assertEq(unsignedLowerBound, uint(1));

        (unsignedUpperBound, unsignedLowerBound) = overlay.unsignedBounds(bytes32("noise"));
        assertEq(unsignedUpperBound, uint(WAD + 10));
        assertEq(unsignedLowerBound, uint(WAD - 5));

        (unsignedUpperBound, unsignedLowerBound) = overlay.unsignedBounds(bytes32("defaultRedemptionRate"));
        assertEq(unsignedUpperBound, uint(RAY + 5));
        assertEq(unsignedLowerBound, uint(RAY - 10));
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
    function test_set_noise() public {
        assertEq(calculator.noise(), uint(0));
        overlay.modifyParameters("noise", uint(WAD + 9));
        assertEq(calculator.noise(), uint(WAD + 9));
    }
    function test_set_defaultRedemptionRate() public {
        assertEq(calculator.defaultRedemptionRate(), uint(0));
        overlay.modifyParameters("defaultRedemptionRate", uint(RAY - 3));
        assertEq(calculator.defaultRedemptionRate(), uint(RAY - 3));
    }
    function test_set_pip() public {
        assertEq(calculator.pip(), int(0));
        overlay.modifyParameters("pip", int(WAD / 2));
        assertEq(calculator.pip(), int(WAD / 2));
    }
    function test_set_pep() public {
        assertEq(calculator.pep(), int(0));
        overlay.modifyParameters("pep", int(WAD / 6));
        assertEq(calculator.pep(), int(WAD / 6));
    }
    function test_set_pdc() public {
        calculator.modifyParameters("pdc", int(100));
        overlay.modifyParameters("pdc", int(RAY * WAD));
        assertEq(calculator.pdc(), int(0));
    }
    function testFail_set_noise_exceed_upper_bound() public {
        overlay.modifyParameters("noise", uint(WAD * 9));
    }
    function testFail_set_noise_exceed_lower_bound() public {
        overlay.modifyParameters("noise", uint(WAD / 9));
    }
    function testFail_set_pip_exceed_upper_bound() public {
        overlay.modifyParameters("pip", int(WAD * RAY + 1));
    }
    function testFail_set_pip_exceed_lower_bound() public {
        overlay.modifyParameters("pip", int(0));
    }
    function testFail_set_uint_unauthed() public {
        user.doModifyParameters(overlay, "noise", uint(WAD + 9));
    }
    function testFail_set_int_unauthed() public {
        user.doModifyParameters(overlay, "pep", int(WAD / 6));
    }
}
