pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract AccountingEngineLike {
    function modifyParameters(bytes32, address) virtual external;
    function modifyParameters(bytes32, uint256) virtual external;
}

contract MinimalAccountingEngineOverlay is GebAuth {
    AccountingEngineLike public accountingEngine;

    constructor(address accountingEngine_) public GebAuth() {
        require(accountingEngine_ != address(0), "MinimalAccountingEngineOverlay/null-address");
        accountingEngine = AccountingEngineLike(accountingEngine_);
    }

    /*
    * @notice Modify the systemStakingPool address inside the AccountingEngine
    * @param parameter Must be "systemStakingPool"
    * @param data The new address for the systemStakingPool
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "systemStakingPool") {
          accountingEngine.modifyParameters(parameter, data);
        }
        else revert("MinimalAccountingEngineOverlay/modify-forbidden-param");
    }
    /*
    * @notice Modify extraSurplusIsTransferred
    * @param parameter Must be "extraSurplusIsTransferred"
    * @param data The new value for extraSurplusIsTransferred
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "extraSurplusIsTransferred") {
          accountingEngine.modifyParameters(parameter, data);
        }
        else revert("MinimalAccountingEngineOverlay/modify-forbidden-param");
    }
}
