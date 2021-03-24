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
    /**
    * @notice Authed function to add contracts that can save SAFEs from liquidation
    * @param saviour SAFE saviour contract to be whitelisted
    **/
    function connectSAFESaviour(address saviour) external isAuthorized {
        liquidationEngine.connectSAFESaviour(saviour);
    }
    /**
    * @notice Governance used function to remove contracts that can save SAFEs from liquidation
    * @param saviour SAFE saviour contract to be removed
    **/
    function disconnectSAFESaviour(address saviour) external isAuthorized {
        liquidationEngine.disconnectSAFESaviour(saviour);
    }
    /*
    * @notice Modify uint256 parameters
    * @param paramter The name of the parameter modified
    * @param val Value for the new parameter
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        liquidationEngine.modifyParameters(parameter, val);
    }
    /**
     * @notice Modify liquidation params
     * @param collateralType The collateral type we change parameters for
     * @param parameter The name of the parameter modified
     * @param val New value for the parameter
     */
    function modifyParameters(bytes32 collateralType, bytes32 parameter, uint256 val) external isAuthorized {
        liquidationEngine.modifyParameters(collateralType, parameter, val);
    }
    /**
     * @notice Modify collateral auction house addresses
     * @param collateralType The collateral type we change parameters for
     * @param parameter The name of the integration modified
     * @param data New address for the integration contract
     */
    function modifyParameters(bytes32 collateralType, bytes32 parameter, address data) external isAuthorized {
        liquidationEngine.modifyParameters(collateralType, parameter, data);
    }
    /**
     * @notice Remove debt that was being auctioned
     * @param rad The amount of debt to withdraw from currentOnAuctionSystemCoins
     */
    function removeCoinsFromAuction(uint256 rad) external isAuthorized {
        liquidationEngine.removeCoinsFromAuction(rad);
    }
}
