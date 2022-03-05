pragma solidity 0.6.7;

import "ds-test/test.sol";

// import "geb/single/AccountingEngine.sol";
import "../../overlays/controller/ControllerSwapOverlay.sol";

contract RateSetterMock {
    address public pidCalculator;

    constructor(address calculator) public {
        pidCalculator = calculator;
    }

    function modifyParameters(bytes32 parameter, address val) external {
        if (parameter == "pidCalculator")
            pidCalculator = val;
    }

    function updateRate(address) external {}
}

contract OracleRelayerMock {
    function redemptionPrice() external returns (uint) {
        return 3 * 10**27;
    }
}

contract CalculatorMock {
    function oll() external pure returns (uint) {
        return 1;
    }

    function dos(uint) external pure returns (uint, int, int) {
        return (
            1646456171,
            -878977039364788994730968,
            -6672548645695324120975822161645
        );
    }

    function sg() external pure returns (int) {
        return 75000000000;
    }

    function ag() external pure returns (int) {
        return 24000;
    }

    function pscl() external pure returns (uint) {
        return 999999711200000000000000000;
    }

    function ips() external pure returns (uint) {
        return 21600;
    }

    function nb() external pure returns (uint) {
        return 1000000000000000000;
    }

    function foub() external pure returns (uint) {
        return 1000000000000000000000000000000000000000000000;
    }

    function folb() external pure returns (int) {
        return -999999999999999999999999999;
    }

    function lut() external pure returns (uint) {
        return 1646456171;
    }

    function pdc() external pure returns (int) {
        return -6672548645695324120975822161645;
    }
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
    OracleRelayerMock oracleRelayer;
    address constant pauseProxy = 0xa57A4e6170930ac547C147CdF26aE4682FA8262E;
    ControllerSwapOverlay overlay;
    CalculatorMock calculator;

    function setUp() public {
        // Local
        calculator = new CalculatorMock();
        rateSetter = new RateSetterMock(address(calculator));
        oracleRelayer = new OracleRelayerMock();
        overlay = new ControllerSwapOverlay(
            pauseProxy,
            RateSetterLike(address(rateSetter)),
            OracleRelayerLike(address(oracleRelayer)),
            3600,
            false
        );

        // Mainnet
        // calculator = CalculatorMock(0xddA334de7A9C57A641616492175ca203Ba8Cf981);
        // rateSetter = RateSetterMock(0x7Acfc14dBF2decD1c9213Db32AE7784626daEb48);
        // oracleRelayer = OracleRelayerMock(0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851);
        // overlay = new ControllerSwapOverlay(
        //     pauseProxy,
        //     RateSetterLike(address(rateSetter)),
        //     OracleRelayerLike(address(oracleRelayer)),
        //     3600,
        //     false
        // );
        // giveAuth(address(rateSetter), address(overlay)); // cheat

        hevm.warp(calculator.lut());
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
        assertEq(address(overlay.oracleRelayer()), address(oracleRelayer));
        assertEq(overlay.updateDelay(), 3600);
        assertTrue(!overlay.isScaled());
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
        (address calc, address calculatorOverlay) = overlay.swapCalculator();

        CalculatorLike newCalculator = CalculatorLike(calc);

        assertEq(calculator.sg(), newCalculator.sg() * 3);
        assertEq(calculator.ag(), newCalculator.ag() * 3);
        assertEq(calculator.pscl(), newCalculator.pscl());
        assertEq(calculator.ips(), newCalculator.ips());
        assertEq(calculator.nb(), newCalculator.nb());
        assertEq(calculator.foub(), newCalculator.foub());
        assertEq(calculator.folb(), newCalculator.folb());
        assertEq(calculator.lut(), newCalculator.lut());
        assertEq(calculator.pdc(), newCalculator.pdc());

        // check imported state matches last state of previous controller
        (uint oldTimestamp, int oldProportionalDeviationObservation, int oldIntegralDeviationObservation) = calculator.dos(calculator.oll() - 1);
        (uint newTimestamp, int newProportionalDeviationObservation, int newIntegralDeviationObservation) = newCalculator.dos(newCalculator.oll() - 1);
        assertEq(oldTimestamp, newTimestamp);
        assertEq(oldProportionalDeviationObservation, newProportionalDeviationObservation);
        assertEq(oldIntegralDeviationObservation, newIntegralDeviationObservation);

        assertEq(rateSetter.pidCalculator(), calc);
        assertEq(newCalculator.seedProposer(), address(rateSetter));
        assertEq(newCalculator.authorities(calculatorOverlay), 1);
        assertEq(newCalculator.authorities(address(overlay)), 0);
        assertTrue(overlay.isScaled());

        hevm.warp(now + 3600);

        (calc, calculatorOverlay) = overlay.swapCalculator();

        newCalculator = CalculatorLike(calc);

        assertEq(calculator.sg(), newCalculator.sg());
        assertEq(calculator.ag(), newCalculator.ag());
        assertEq(calculator.pscl(), newCalculator.pscl());
        assertEq(calculator.ips(), newCalculator.ips());
        assertEq(calculator.nb(), newCalculator.nb());
        assertEq(calculator.foub(), newCalculator.foub());
        assertEq(calculator.folb(), newCalculator.folb());
        assertEq(calculator.lut(), newCalculator.lut());
        assertEq(calculator.pdc(), newCalculator.pdc());

        (newTimestamp, newProportionalDeviationObservation, newIntegralDeviationObservation) = newCalculator.dos(newCalculator.oll() - 1);
        assertEq(oldTimestamp, newTimestamp);
        assertEq(oldProportionalDeviationObservation, newProportionalDeviationObservation);
        assertEq(oldIntegralDeviationObservation, newIntegralDeviationObservation);

        assertEq(rateSetter.pidCalculator(), calc);
        assertEq(newCalculator.seedProposer(), address(rateSetter));
        assertEq(newCalculator.authorities(calculatorOverlay), 1);
        assertEq(newCalculator.authorities(address(overlay)), 0);
        assertTrue(!overlay.isScaled());
    }

    function testFail_swap_controller_unauthed() public {
        overlay.removeAuthorization(address(this));
        overlay.swapCalculator();
    }
    function testFail_swap_controller_too_early() public {
        overlay.swapCalculator();
        hevm.warp(now+3599);
        overlay.swapCalculator();
    }
}
