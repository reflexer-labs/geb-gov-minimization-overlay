pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";
import "../minimal/MinimalRrfmCalculatorOverlay.sol";
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
contract ControllerSwapOverlay is GebAuth {

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

    // Overlay bounds
    struct OverlayBounds {
        bytes32[] unsignedParams;
        bytes32[] signedParams;
        uint256[] unsignedUpperBounds;
        uint256[] unsignedLowerBounds;
        int256[]  signedUpperBounds;
        int256[]  signedLowerBounds;
    }
    OverlayBounds[] bounds;

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

        pauseProxy = _pauseProxy;
        rateSetter = _rateSetter;
        oracleRelayer = _oracleRelayer;
        updateDelay = _updateDelay;
        isScaled = _isScaled;


        // populate bounds - index 0 == raw
        bounds.push(OverlayBounds(
            new bytes32[](0),
            new bytes32[](0),
            new uint256[](0),
            new uint256[](0),
            new int256[](0),
            new int256[](0)
        ));

        // index 1 == scaled
        bounds.push(OverlayBounds(
            new bytes32[](0),
            new bytes32[](0),
            new uint256[](0),
            new uint256[](0),
            new int256[](0),
            new int256[](0)
        ));
    }

    // Math
    int256 constant RAY = 10 ** 27;

    function imul(int256 x, int256 y) internal pure returns (int256 z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    /**
     * @notice Will swap between a raw and scaled controllers, keeping the same parameters
     */
    function swapCalculator() external isAuthorized returns (address calculator, address overlay) {
        require(lastUpdateTime + updateDelay <= block.timestamp, "ControllerSwapOverlay/too-early");

        CalculatorLike currentCalculator = CalculatorLike(rateSetter.pidCalculator());
        uint256 redemptionPrice = oracleRelayer.redemptionPrice();

        // Fetch last observation data to populate next controller state
        (
            uint256 deviationTimestamp,
            int256  deviationProportional,
            int256  deviationIntegral
        ) = currentCalculator.dos(currentCalculator.oll() - 1);

        int256[] memory currentState = new int256[](5);
        currentState[0] = int256(currentCalculator.lut());
        currentState[1] = deviationProportional;
        currentState[2] = deviationIntegral;
        currentState[3] = currentCalculator.pdc();
        currentState[4] = int256(deviationTimestamp);

        if (isScaled)
            calculator = address(new PIRawPerSecondCalculator(
                imul(currentCalculator.sg(), int256(redemptionPrice)) / RAY, // kp
                imul(currentCalculator.ag(), int256(redemptionPrice)) / RAY, // ki
                currentCalculator.pscl(),                                    // perSecondCumulativeLeak
                currentCalculator.ips(),                                     // integralPeriodSize
                currentCalculator.nb(),                                      // noiseBarrier
                currentCalculator.foub(),                                    // feedbackOutputUpperBound
                currentCalculator.folb(),                                    // feedbackOutputLowerBound
                currentState
            ));
        else
            calculator = address(new PIScaledPerSecondCalculator(
                imul(currentCalculator.sg(), RAY) / int(redemptionPrice),    // kp
                imul(currentCalculator.ag(), RAY) / int(redemptionPrice),    // ki
                currentCalculator.pscl(),                                    // perSecondCumulativeLeak
                currentCalculator.ips(),                                     // integralPeriodSize
                currentCalculator.nb(),                                      // noiseBarrier
                currentCalculator.foub(),                                    // feedbackOutputUpperBound
                currentCalculator.folb(),                                    // feedbackOutputLowerBound
                currentState
            ));

        // set allReaderToggle
        CalculatorLike(calculator).modifyParameters("allReaderToggle", 1);

        // swap controller con rate setter
        rateSetter.modifyParameters("pidCalculator", calculator);
        CalculatorLike(calculator).modifyParameters("seedProposer", address(rateSetter));

        uint256 boundsIndex = (isScaled) ? 0 : 1;

        // overlay
        overlay = address(new MinimalRrfmCalculatorOverlay(
            calculator,
            bounds[boundsIndex].unsignedParams,
            bounds[boundsIndex].signedParams,
            bounds[boundsIndex].unsignedUpperBounds,
            bounds[boundsIndex].unsignedLowerBounds,
            bounds[boundsIndex].signedUpperBounds,
            bounds[boundsIndex].signedLowerBounds
        ));

        // auth
        CalculatorLike(calculator).addAuthority(overlay);
        CalculatorLike(calculator).removeAuthority(address(this));

        isScaled = !isScaled;
        lastUpdateTime = now;
    }
}