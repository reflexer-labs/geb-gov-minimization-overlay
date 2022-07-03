pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract LiquidationEngineLike {
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) external virtual;
    function connectSAFESaviour(address) virtual external;
    function disconnectSAFESaviour(address) virtual external;
}

contract MinimalLiquidationEngineOverlay is GebAuth {
    // Minimum and maximum possible penalty for any collateral type liquidation
    uint256               public minPenalty;
    uint256               public maxPenalty;

    LiquidationEngineLike public liquidationEngine;

    constructor(address liquidationEngine_, uint256 minPenalty_, uint256 maxPenalty_) public GebAuth() {
        require(liquidationEngine_ != address(0), "MinimalLiquidationEngineOverlay/null-address");
        require(both(minPenalty_ < maxPenalty_, minPenalty_ > 0), "MinimalLiquidationEngineOverlay/invalid-penalty-bounds");

        liquidationEngine = LiquidationEngineLike(liquidationEngine_);
        minPenalty        = minPenalty_;
        maxPenalty        = maxPenalty_;
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    /**
     * @notice Modify a collateral's liquidation penalty
     * @param collateralType The collateral type we change parameters for
     * @param parameter The name of the parameter (must be "liquidationPenalty")
     * @param data New value for the penalty
     */
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) external isAuthorized {
        require(parameter == "liquidationPenalty", "MinimalLiquidationEngineOverlay/invalid-param-name");
        require(both(data >= minPenalty, data <= maxPenalty), "MinimalLiquidationEngineOverlay/invalid-new-penalty");
        liquidationEngine.modifyParameters(collateralType, parameter, data);
    }

    /*
    * @notify Connect a new safe saviour to the LiquidationEngine
    * @param saviour The new saviour address
    */
    function connectSAFESaviour(address saviour) external isAuthorized {
        liquidationEngine.connectSAFESaviour(saviour);
    }
    /*
    * @notify Disconnect an existing safe saviour from the LiquidationEngine
    * @param saviour The saviour address to disconnect
    */
    function disconnectSAFESaviour(address saviour) external isAuthorized {
        liquidationEngine.disconnectSAFESaviour(saviour);
    }
}
