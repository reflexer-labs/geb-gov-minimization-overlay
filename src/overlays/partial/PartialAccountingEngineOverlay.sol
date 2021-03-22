pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract AccountingEngineLike {
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, address) virtual external;
}

contract PartialAccountingEngineOverlay is GebAuth {
    // --- Variables ---
    AccountingEngineLike public accountingEngine;

    constructor(address accountingEngine_) public GebAuth() {
        require(accountingEngine_ != address(0), "PartialSAFEEngineOverlay/null-accounting-engine");
        accountingEngine = AccountingEngineLike(accountingEngine_);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Core Logic ---
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        require(
          both(parameter != "lastSurplusAuctionTime", parameter != "extraSurplusIsTransferred"),
          "PartialAccountingEngineOverlay/forbidden-param"
        );
        accountingEngine.modifyParameters(parameter, val);
    }

    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(
          both(
            both(parameter != "postSettlementSurplusDrain", parameter != "protocolTokenAuthority"),
            both(parameter != "surplusAuctionHouse", parameter != "debtAuctionHouse")
          ), "PartialAccountingEngineOverlay/forbidden-param"
        );

        accountingEngine.modifyParameters(parameter, data);
    }
}
