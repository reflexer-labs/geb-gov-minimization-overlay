pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract GlobalSettlementLike {
    function modifyParameters(bytes32, address) virtual external;
    function modifyParameters(bytes32, uint256) virtual external;
    function shutdownSystem() virtual external;
}

contract PartialGlobalSettlementOverlay is GebAuth {
    // --- Variables ---
    GlobalSettlementLike public globalSettlement;

    constructor(address globalSettlement_) public GebAuth() {
        require(globalSettlement_ != address(0), "PartialGlobalSettlementOverlay/null-settlement");
        globalSettlement = GlobalSettlementLike(globalSettlement_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Core Logic ---
    /*
    * @notify Modify the address of the stabilityFeeTreasury
    * @param parameter Must be "stabilityFeeTreasury"
    * @param data The new address for the stabilityFeeTreasury
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(parameter == "stabilityFeeTreasury", "PartialGlobalSettlementOverlay/forbidden-param");
        globalSettlement.modifyParameters(parameter, data);
    }
    /*
    * @notify Modify an uint256 parameter
    * @param parameter The name of the parameter to modify
    * @param val The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        globalSettlement.modifyParameters(parameter, val);
    }
    /**
     * @notice Freeze the system and start the cooldown period
     */
    function shutdownSystem() external isAuthorized {
        globalSettlement.shutdownSystem();
    }
}
