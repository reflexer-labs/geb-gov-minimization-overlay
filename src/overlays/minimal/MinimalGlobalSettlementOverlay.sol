pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract GlobalSettlementLike {
    function shutdownSystem() external virtual;
}

contract MinimalGlobalSettlementOverlay is GebAuth {
    uint256              public settlementDelay;
    uint256              public settlementExecutionDate;

    GlobalSettlementLike public globalSettlement;

    constructor(address globalSettlement_, uint256 settlementDelay_) public GebAuth() {
        require(globalSettlement_ != address(0), "MinimalGlobalSettlementOverlay/null-address");
        require(settlementDelay_ > 0, "MinimalGlobalSettlementOverlay/invalid-settlement-delay");

        globalSettlement = GlobalSettlementLike(globalSettlement_);
        settlementDelay  = settlementDelay_;
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MinimalGlobalSettlementOverlay/add-uint-uint-overflow");
    }

    /*
    * @notice Start shutdown procedure
    */
    function startShutdownProcedure() external isAuthorized {
        require(settlementExecutionDate == 0, "MinimalGlobalSettlementOverlay/shutdown-already-started");
        settlementExecutionDate = addition(now, settlementDelay);
    }

    /*
    * @notice Stop shutdown procedure
    */
    function stopShutdownProcedure() external isAuthorized {
        settlementExecutionDate = 0;
    }

    /*
    * @notice Trigger settlement for the system
    */
    function shutdownSystem() external {
        require(both(settlementExecutionDate > 0, now > settlementExecutionDate), "MinimalGlobalSettlementOverlay/cannot-settle");
        settlementExecutionDate = 0;
        globalSettlement.shutdownSystem();
    }
}
