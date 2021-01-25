pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract LiquidationEngineLike {
    function connectSAFESaviour(address) virtual external;
    function disconnectSAFESaviour(address) virtual external;
    function modifyParameters(bytes32, uint256) virtual external;
}
contract LiquidationEngineOverlay is GebAuth {
    LiquidationEngineLike public liquidationEngine;

    constructor(address liquidationEngine_) public GebAuth() {
        require(liquidationEngine_ != address(0), "LiquidationEngineOverlay/null-address");
        liquidationEngine = LiquidationEngineLike(liquidationEngine_);
    }

    function connectSAFESaviour(address saviour) external isAuthorized {
        liquidationEngine.connectSAFESaviour(saviour);
    }
    function disconnectSAFESaviour(address saviour) external isAuthorized {
        liquidationEngine.disconnectSAFESaviour(saviour);
    }
}
