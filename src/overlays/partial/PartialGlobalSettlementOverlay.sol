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
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(either(
          either(parameter == "oracleRelayer", parameter == "coinSavingsAccount"),
          parameter == "stabilityFeeTreasury"
        ), "PartialGlobalSettlementOverlay/forbidden-param");
        globalSettlement.modifyParameters(parameter, data);
    }

    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        globalSettlement.modifyParameters(parameter, val);
    }

    function shutdownSystem() external isAuthorized {
        globalSettlement.shutdownSystem();
    }
}
