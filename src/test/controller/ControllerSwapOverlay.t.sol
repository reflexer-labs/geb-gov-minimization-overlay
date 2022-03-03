pragma solidity 0.6.7;

import "ds-test/test.sol";

// import "geb/single/AccountingEngine.sol";
import "../../overlays/controller/ControllerSwapOverlay.sol";

contract RateSetterMock {
    address public pidCalculator;

    function modifyParameters(bytes32 parameter, address val) external {
        if (parameter == "pidCalculator")
            pidCalculator = val;
    }

    function updateRate(address) external {}
}

abstract contract AuthLike {
    function authorizedAccounts(address) external view virtual returns (uint256);
}

interface Hevm {
    function warp(uint256) external;

    function roll(uint256) external;

    function store(
        address,
        bytes32,
        bytes32
    ) external;

    function store(
        address,
        bytes32,
        address
    ) external;

    function load(address, bytes32) external view returns (bytes32);
}

contract ControllerSwapOverlayTest is DSTest {
    Hevm hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    RateSetterMock rateSetter;
    address constant pauseProxy = 0xa57A4e6170930ac547C147CdF26aE4682FA8262E;
    ControllerSwapOverlay overlay;
    // User user;

    uint256 internal constant NEGATIVE_RATE_LIMIT         = TWENTY_SEVEN_DECIMAL_NUMBER - 1;
    uint256 internal constant TWENTY_SEVEN_DECIMAL_NUMBER = 10 ** 27;
    uint256 internal constant EIGHTEEN_DECIMAL_NUMBER     = 10 ** 18;

    int256 Kp                                 = int(EIGHTEEN_DECIMAL_NUMBER);
    int256 Ki                                 = int(EIGHTEEN_DECIMAL_NUMBER);
    uint256 integralPeriodSize                = 3600;
    uint256 perSecondCumulativeLeak           = 999997208243937652252849536; // 1% per hour
    uint256 noiseBarrier                      = EIGHTEEN_DECIMAL_NUMBER;
    uint256 feedbackOutputUpperBound          = TWENTY_SEVEN_DECIMAL_NUMBER * EIGHTEEN_DECIMAL_NUMBER;
    int256  feedbackOutputLowerBound          = -int(NEGATIVE_RATE_LIMIT);

    function setUp() public {
        hevm.warp(1e6);

        // Local
        rateSetter = new RateSetterMock();
        overlay = new ControllerSwapOverlay(pauseProxy, RateSetterLike(address(rateSetter)), 3600);

        // Mainnet
        // rateSetter = RateSetterMock(0x7Acfc14dBF2decD1c9213Db32AE7784626daEb48);
        // overlay = new ControllerSwapOverlay(pauseProxy, RateSetterLike(address(rateSetter)), 3600);
        // giveAuth(address(rateSetter), address(overlay)); // cheat
    }

    function giveAuth(address _base, address target) internal {
        AuthLike base = AuthLike(_base);

        // Edge case - ward is already set
        if (base.authorizedAccounts(target) == 1) return;

        for (int256 i = 0; i < 100; i++) {
            // Scan the storage for the authed account storage slot
            bytes32 prevValue = hevm.load(address(base), keccak256(abi.encode(target, uint256(i))));
            hevm.store(address(base), keccak256(abi.encode(target, uint256(i))), bytes32(uint256(1)));
            if (base.authorizedAccounts(target) == 1) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                hevm.store(address(base), keccak256(abi.encode(target, uint256(i))), prevValue);
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

    function test_setup() public {
        assertEq(address(overlay.pauseProxy()), address(pauseProxy));
        assertEq(address(overlay.rateSetter()), address(rateSetter));
        assertEq(address(overlay.rateSetter()), address(rateSetter));
    }
    function test_add_auth() public {
        overlay.addAuthorization(address(0x3));
        assertEq(overlay.authorizedAccounts(address(0x3)), 1);
    }
    function test_remove_auth() public {
        overlay.removeAuthorization(address(this));
        assertEq(overlay.authorizedAccounts(address(this)), 0);
    }
    function test_swap_controller() public {
        (address calc, address calculatorOverlay) = overlay.swapCalculator(
            Kp,
            Ki,
            perSecondCumulativeLeak,
            integralPeriodSize,
            noiseBarrier,
            feedbackOutputUpperBound,
            feedbackOutputLowerBound
        );

        PIRawPerSecondCalculator calculator = PIRawPerSecondCalculator(calc);

        assertEq(rateSetter.pidCalculator(), calc);
        assertEq(calculator.seedProposer(), address(rateSetter));
        assertEq(calculator.authorities(calculatorOverlay), 1);
        assertEq(calculator.authorities(address(overlay)), 0);
        assertTrue(overlay.isScaled());
    }

    function testFail_swap_controller_unauthed() public {
        overlay.removeAuthorization(address(this));
        overlay.swapCalculator(
            Kp,
            Ki,
            perSecondCumulativeLeak,
            integralPeriodSize,
            noiseBarrier,
            feedbackOutputUpperBound,
            feedbackOutputLowerBound
        );
    }
    function testFail_swap_controller_too_early() public {
        overlay.swapCalculator(
            Kp,
            Ki,
            perSecondCumulativeLeak,
            integralPeriodSize,
            noiseBarrier,
            feedbackOutputUpperBound,
            feedbackOutputLowerBound
        );
        hevm.warp(now+3599);
        overlay.swapCalculator(
            Kp,
            Ki,
            perSecondCumulativeLeak,
            integralPeriodSize,
            noiseBarrier,
            feedbackOutputUpperBound,
            feedbackOutputLowerBound
        );
    }
}
