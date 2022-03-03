pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";
import "../minimal/MinimalRrfmCalculatorOverlay.sol";
import "geb-rrfm-calculators/calculator/PIRawPerSecondCalculator.sol";
import "geb-rrfm-calculators/calculator/PIScaledPerSecondCalculator.sol";

abstract contract RateSetterLike {
    function modifyParameters(bytes32, address) external virtual;
    function updateRate(address) external virtual;
}

abstract contract CalculatorLike {
    function modifyParameters(bytes32, address) external virtual;
    function addAuthority(address) external virtual;
    function removeAuthority(address) external virtual;
}

// @notice Swaps between raw and scaled controllers
// @dev Needs to be authed in rateSetter
contract ControllerSwapOverlay is GebAuth {

    address public immutable pauseProxy;
    bool public isScaled;
    uint256 public lastUpdateTime;
    uint256 public immutable updateDelay;
    RateSetterLike public immutable rateSetter;

    // raw calculator bounds
    bytes32[] unsignedParams;
    bytes32[] signedParams;
    uint256[] unsignedUpperBounds;
    uint256[] unsignedLowerBounds;
    int256[] signedUpperBounds;
    int256[] signedLowerBounds;

    constructor(address _pauseProxy, RateSetterLike _rateSetter, uint256 _updateDelay) public GebAuth() {
        pauseProxy = _pauseProxy;
        rateSetter = _rateSetter;
        updateDelay = _updateDelay;
    }

    function swapCalculator(
            int256 Kp,
            int256 Ki,
            uint256 perSecondCumulativeLeak,
            uint256 integralPeriodSize,
            uint256 noiseBarrier,
            uint256 feedbackOutputUpperBound,
            int256  feedbackOutputLowerBound
    ) external isAuthorized returns (address calculator, address overlay) {
        require(lastUpdateTime + updateDelay < block.timestamp, "ControllerSwapOverlay/too-early");
        if (isScaled)
            calculator = address(new PIRawPerSecondCalculator(
                Kp,
                Ki,
                perSecondCumulativeLeak,
                integralPeriodSize,
                noiseBarrier,
                feedbackOutputUpperBound,
                feedbackOutputLowerBound,
                new int256[](0)
            ));
        else
            calculator = address(new PIScaledPerSecondCalculator(
                Kp,
                Ki,
                perSecondCumulativeLeak,
                integralPeriodSize,
                noiseBarrier,
                feedbackOutputUpperBound,
                feedbackOutputLowerBound,
                new int256[](5)
            ));

        // swap controller con rate setter
        rateSetter.modifyParameters("pidCalculator", calculator);
        CalculatorLike(calculator).modifyParameters("seedProposer", address(rateSetter));

        // overlay
        overlay = address(new MinimalRrfmCalculatorOverlay(
            calculator,
            unsignedParams,
            signedParams,
            unsignedUpperBounds,
            unsignedLowerBounds,
            signedUpperBounds,
            signedLowerBounds
        ));

        // auth
        CalculatorLike(calculator).addAuthority(overlay);
        CalculatorLike(calculator).removeAuthority(address(this));

        // call updateRate
        rateSetter.updateRate(address(0x83533fdd3285f48204215E9CF38C785371258E76)); // GEB_STABILITY_FEE_TREASURY

        isScaled = !isScaled;
    }
}