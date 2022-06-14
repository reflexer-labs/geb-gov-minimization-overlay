pragma solidity 0.6.7;

import "geb-rrfm-calculators/calculator/PIRawPerSecondCalculator.sol";
import "geb-rrfm-calculators/calculator/PIScaledPerSecondCalculator.sol";

contract ControllerFactory {
    function deployRAWPIDController(
        int256 kp,
        int256 ki,
        uint256 perSecondCumulativeLeak,
        uint256 integralPeriodSize,
        uint256 noiseBarrier,
        uint256 feedbackOutputUpperBound,
        int256 feedbackOutputLowerBound,
        int256[] memory importedState
    ) public returns (address) {
        PIRawPerSecondCalculator controller = new PIRawPerSecondCalculator(
            kp,
            ki,
            perSecondCumulativeLeak,
            integralPeriodSize,
            noiseBarrier,
            feedbackOutputUpperBound,
            feedbackOutputLowerBound,
            importedState
        );
        controller.addAuthority(msg.sender);
        controller.removeAuthority(address(this));
        return address(controller);
    }

    function deployScaledPIDController(
        int256 kp,
        int256 ki,
        uint256 perSecondCumulativeLeak,
        uint256 integralPeriodSize,
        uint256 noiseBarrier,
        uint256 feedbackOutputUpperBound,
        int256 feedbackOutputLowerBound,
        int256[] memory importedState
    ) public returns (address) {
        PIScaledPerSecondCalculator controller = new PIScaledPerSecondCalculator(
            kp,
            ki,
            perSecondCumulativeLeak,
            integralPeriodSize,
            noiseBarrier,
            feedbackOutputUpperBound,
            feedbackOutputLowerBound,
            importedState
        );
        controller.addAuthority(msg.sender);
        controller.removeAuthority(address(this));
        return address(controller);
    }
}