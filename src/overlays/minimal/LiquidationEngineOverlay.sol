pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract LiquidationEngineLike {
    function connectSAFESaviour(address) virtual external;
    function disconnectSAFESaviour(address) virtual external;
}
contract LiquidationEngineOverlay is GebAuth {
    LiquidationEngineLike public liquidationEngine;

    constructor(address liquidationEngine_) public GebAuth() {
        require(liquidationEngine_ != address(0), "LiquidationEngineOverlay/null-address");
        liquidationEngine = LiquidationEngineLike(liquidationEngine_);
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
