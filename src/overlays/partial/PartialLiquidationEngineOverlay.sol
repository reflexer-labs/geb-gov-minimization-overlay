pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract LiquidationEngineLike {
    function connectSAFESaviour(address) virtual external;
    function disconnectSAFESaviour(address) virtual external;
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, bytes32, uint256) virtual external;
    function modifyParameters(bytes32, bytes32, address) virtual external;
    function removeCoinsFromAuction(uint256) virtual public;
}

contract PartialLiquidationEngineOverlay is GebAuth {
    // --- Variables ---
    LiquidationEngineLike public liquidationEngine;

    constructor(address liquidationEngine_) public GebAuth() {
        require(liquidationEngine_ != address(0), "PartialSAFEEngineOverlay/null-liquidation-engine");
        liquidationEngine = LiquidationEngineLike(liquidationEngine_);
    }

    // --- Core Logic ---
    function connectSAFESaviour(address saviour) external isAuthorized {
        liquidationEngine.connectSAFESaviour(saviour);
    }

    function disconnectSAFESaviour(address saviour) external isAuthorized {
        liquidationEngine.disconnectSAFESaviour(saviour);
    }

    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        liquidationEngine.modifyParameters(parameter, val);
    }

    function modifyParameters(bytes32 collateralType, bytes32 parameter, uint256 val) external isAuthorized {
        liquidationEngine.modifyParameters(collateralType, parameter, val);
    }

    function modifyParameters(bytes32 collateralType, bytes32 parameter, address data) external isAuthorized {
        liquidationEngine.modifyParameters(collateralType, parameter, data);
    }

    function removeCoinsFromAuction(uint256 rad) external isAuthorized {
        liquidationEngine.removeCoinsFromAuction(rad);
    }
}
