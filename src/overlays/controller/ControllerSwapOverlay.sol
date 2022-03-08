pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";
import "../minimal/MinimalRrfmCalculatorOverlay.sol";
import "geb-rrfm-calculators/math/SignedSafeMath.sol";
import "geb-rrfm-calculators/calculator/PIRawPerSecondCalculator.sol";
import "geb-rrfm-calculators/calculator/PIScaledPerSecondCalculator.sol";

abstract contract RateSetterLike {
    function modifyParameters(bytes32, address) external virtual;
    function updateRate(address) external virtual;
    function pidCalculator() external virtual view returns (address);
}

abstract contract CalculatorLike {
    function modifyParameters(bytes32, address) external virtual;
    function modifyParameters(bytes32, uint256) external virtual;
    function addAuthority(address) external virtual;
    function removeAuthority(address) external virtual;
    function seedProposer() external virtual view returns (address);
    function authorities(address) external virtual view returns (uint);
    function sg() external virtual view returns (int256);
    function ag() external virtual view returns (int256);
    function pscl() external virtual view returns (uint256);
    function ips() external virtual view returns (uint256);
    function nb() external virtual view returns (uint256);
    function foub() external virtual view returns (uint256);
    function folb() external virtual view returns (int256);
    function pdc() external virtual view returns (int256);
    function lut() external virtual view returns (uint256);
    function oll() external virtual view returns (uint256);
    function dos(uint256) external virtual view returns (uint256, int256, int256);

}

abstract contract OracleRelayerLike {
    function redemptionPrice() virtual external returns (uint256);
}
// @notice Swaps between raw and scaled controllers
// @dev Needs to be authed in rateSetter
contract ControllerSwapOverlay is GebAuth, SignedSafeMath {

    // State vars
    address           public immutable pauseProxy;
    RateSetterLike    public immutable rateSetter;
    OracleRelayerLike public immutable oracleRelayer;

    // delay enforced between controller swaps
    uint256           public immutable updateDelay;
    // last time a controller swap happened
    uint256           public           lastUpdateTime;
    // true if the current controller is scaled
    bool              public           isScaled;

    // Overlay bounds (raw)
    bytes32[] unsignedParams      = [bytes32("pscl")];
    bytes32[] signedParams        = [bytes32("sg"), bytes32("ag")];
    uint256[] unsignedUpperBounds = [1000000000000000000000000000];
    uint256[] unsignedLowerBounds = [999998844239760000000000000];
    int256[] signedUpperBounds    = [400000000000, 100000];
    int256[] signedLowerBounds    = [10000000000, 0];

    int256 constant RAY = 10 ** 27;

    // Event
    event ControllerDeployed(address controller, address overlay);

    /**
     * @notice Constructor
     * @param _pauseProxy Address of pause.proxy()
     * @param _rateSetter Address of the rate setter
     * @param _oracleRelayer Address of the oracle relayer
     * @param _updateDelay Delay enforced betweed controller swaps
     * @param _isScaled True if current controller is scaled
     */
    constructor(
        address           _pauseProxy,
        RateSetterLike    _rateSetter,
        OracleRelayerLike _oracleRelayer,
        uint256           _updateDelay,
        bool              _isScaled
    ) public GebAuth() {
        require(_pauseProxy != address(0), "ControllerSwapOverlay/invalid-pause-proxy");
        require(address(_rateSetter) != address(0), "ControllerSwapOverlay/invalid-rate-setter");
        require(address(_oracleRelayer) != address(0), "ControllerSwapOverlay/invalid-oracle-relayer");
        require(_updateDelay > 0, "ControllerSwapOverlay/invalid-update-delay");
        pauseProxy = _pauseProxy;
        rateSetter = _rateSetter;
        oracleRelayer = _oracleRelayer;
        updateDelay = _updateDelay;
        isScaled = _isScaled;
    }

    // Internal functions
    /**
     * @notice Returns a PID Controller current state
     * @param calculator PID controller
    **/
    function getCalculatorState(CalculatorLike calculator) internal view returns (int256[] memory state) {
        (
            uint256 deviationTimestamp,
            int256  deviationProportional,
            int256  deviationIntegral
        ) = calculator.dos(calculator.oll() - 1);

        state = new int256[](5);
        state[0] = int256(calculator.lut());      // lastUpdateTime
        state[1] = deviationProportional;           // deviationObservations.proportional
        state[2] = deviationIntegral;               // deviationObservations.integral
        state[3] = calculator.pdc();              // priceDeviationCumulative
        state[4] = int256(deviationTimestamp);      // deviationObservations.timestamp
    }

    /**
     * @notice Deploys and attaches an overlay to a new controller
     * @param calculator New controller being deployed
     * @param redemptionPrice Current redemption price (RAY)
    **/
    function setupOverlay(address calculator, int256 redemptionPrice) internal returns (address) {
        // deploy new overlay
        MinimalRrfmCalculatorOverlay overlay = new MinimalRrfmCalculatorOverlay(
            calculator,
            unsignedParams,
            signedParams,
            unsignedUpperBounds,
            unsignedLowerBounds,
            isScaled ? signedUpperBounds : adjustSignedBoundsForScaledPID(signedUpperBounds, redemptionPrice),
            isScaled ? signedLowerBounds : adjustSignedBoundsForScaledPID(signedLowerBounds, redemptionPrice)

        );

        // auth
        CalculatorLike(calculator).addAuthority(address(overlay));
        overlay.addAuthorization(pauseProxy);
        overlay.removeAuthorization(address(this));

        return address(overlay);
    }

    /**
     * @notice Adjusts bounds for Scaled PID Controller (divides bounds by current redemptionPrice)
     * @param bounds Aray of bounds
     * @param redemptionPrice Current redemption price (RAY)
    **/
    function adjustSignedBoundsForScaledPID(int256[] memory bounds, int256 redemptionPrice) internal pure returns (int256[] memory) {
        uint256 length = bounds.length;
        for (uint256 i; i < length; i++)
            bounds[i] = divide(multiply(bounds[i], redemptionPrice), RAY);

        return bounds;
    }

    // External functions
    /**
     * @notice Will swap between a raw and scaled controllers, keeping the same parameters
     */
    function swapCalculator() external isAuthorized returns (address calculator, address overlay) {
        require(lastUpdateTime + updateDelay <= block.timestamp, "ControllerSwapOverlay/too-early");

        CalculatorLike currentCalculator = CalculatorLike(rateSetter.pidCalculator());
        int256 redemptionPrice = int256(oracleRelayer.redemptionPrice());

        // Fetch last observation data to populate next controller state
        int256[] memory currentState = getCalculatorState(currentCalculator);

        if (isScaled)
            calculator = address(new PIRawPerSecondCalculator(
                divide(multiply(currentCalculator.sg(), RAY), redemptionPrice), // kp
                divide(multiply(currentCalculator.ag(), RAY), redemptionPrice), // ki
                currentCalculator.pscl(),                                       // perSecondCumulativeLeak
                currentCalculator.ips(),                                        // integralPeriodSize
                currentCalculator.nb(),                                         // noiseBarrier
                currentCalculator.foub(),                                       // feedbackOutputUpperBound
                currentCalculator.folb(),                                       // feedbackOutputLowerBound
                currentState
            ));
        else
            calculator = address(new PIScaledPerSecondCalculator(
                divide(multiply(currentCalculator.sg(), redemptionPrice), RAY), // kp
                divide(multiply(currentCalculator.ag(), redemptionPrice), RAY), // ki
                currentCalculator.pscl(),                                       // perSecondCumulativeLeak
                currentCalculator.ips(),                                        // integralPeriodSize
                currentCalculator.nb(),                                         // noiseBarrier
                currentCalculator.foub(),                                       // feedbackOutputUpperBound
                currentCalculator.folb(),                                       // feedbackOutputLowerBound
                currentState
            ));

        // set allReaderToggle
        CalculatorLike(calculator).modifyParameters("allReaderToggle", 1);

        // swap controller con rate setter
        rateSetter.modifyParameters("pidCalculator", calculator);
        CalculatorLike(calculator).modifyParameters("seedProposer", address(rateSetter));

        // overlay
        overlay = setupOverlay(calculator, redemptionPrice);

        CalculatorLike(calculator).removeAuthority(address(this));

        isScaled = !isScaled;
        lastUpdateTime = now;

        emit ControllerDeployed(calculator, overlay);
    }
}