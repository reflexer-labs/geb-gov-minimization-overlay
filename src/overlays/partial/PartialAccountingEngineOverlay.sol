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
    /**
     * @notice Modify an uint256 param aside from lastSurplusAuctionTime and extraSurplusIsTransferred
     * @param parameter The name of the parameter modified
     * @param val New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        require(
          both(parameter != "lastSurplusAuctionTime", parameter != "extraSurplusIsTransferred"),
          "PartialAccountingEngineOverlay/forbidden-param"
        );
        accountingEngine.modifyParameters(parameter, val);
    }
    /**
     * @notice Modify the systemStakingPool
     * @param parameter Must be "systemStakingPool"
     * @param data New address for the parameter
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(parameter == "systemStakingPool", "PartialAccountingEngineOverlay/forbidden-param");
        accountingEngine.modifyParameters(parameter, data);
    }
}
