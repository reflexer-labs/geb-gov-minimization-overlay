pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract SFTreasuryCoreParamAdjusterLike {
    function modifyParameters(bytes32 parameter, uint256 val) external virtual;
    function modifyParameters(address targetContract, bytes4 targetFunction, bytes32 parameter, uint256 val) external virtual;
}

contract MinimalSFTreasuryCoreParamAdjusterOverlay is GebAuth {
    SFTreasuryCoreParamAdjusterLike public adjuster;

    constructor(address adjuster_) public GebAuth() {
        require(adjuster_ != address(0), "MinimalSFTreasuryCoreParamAdjusterOverlay/null-adjuster");
        adjuster = SFTreasuryCoreParamAdjusterLike(adjuster_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Core Logic ---
    /*
    * @notice Modify minPullFundsThreshold or pullFundsMinThresholdMultiplier
    * @param parameter Must be "minPullFundsThreshold" or "pullFundsMinThresholdMultiplier"
    * @param data The new value
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        require(
          either(parameter == "minPullFundsThreshold", parameter == "pullFundsMinThresholdMultiplier"),
          "MinimalSFTreasuryCoreParamAdjusterOverlay/invalid-parameter"
        );
        adjuster.modifyParameters(parameter, data);
    }

    /*
    * @notify Modify "latestExpectedCalls" for a FundedFunction
    * @param targetContract The contract where the funded function resides
    * @param targetFunction The signature of the funded function
    * @param parameter Must be "latestExpectedCalls"
    * @param val The new parameter value
    */
    function modifyParameters(address targetContract, bytes4 targetFunction, bytes32 parameter, uint256 val) external isAuthorized {
        require(parameter == "latestExpectedCalls", "MinimalSFTreasuryCoreParamAdjusterOverlay/invalid-parameter");
        adjuster.modifyParameters(targetContract, targetFunction, parameter, val);
    }
}
