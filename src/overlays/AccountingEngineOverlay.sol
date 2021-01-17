pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract AccountingEngineLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract AccountingEngineOverlay is GebAuth {
    AccountingEngineLike public accountingEngine;

    constructor(address accountingEngine_) public GebAuth() {
        require(accountingEngine_ != address(0), "AccountingEngineOverlay/null-address");
        accountingEngine = AccountingEngineLike(accountingEngine_);
    }

    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "systemStakingPool") {
          accountingEngine.modifyParameters(parameter, data);
        } else revert("AccountingEngineOverlay/modify-forbidden-param");
    }
}
