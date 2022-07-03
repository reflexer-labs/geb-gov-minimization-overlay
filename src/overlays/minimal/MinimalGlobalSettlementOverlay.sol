pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract GlobalSettlementLike {
    function shutdownSystem() external virtual;
}

contract MinimalGlobalSettlementOverlay is GebAuth {
    GlobalSettlementLike public globalSettlement;

    constructor(address globalSettlement_) public GebAuth() {
        require(globalSettlement_ != address(0), "MinimalGlobalSettlementOverlay/null-address");
        globalSettlement = GlobalSettlementLike(globalSettlement_);
    }

    /*
    * @notice Trigger settlement for the system
    */
    function shutdownSystem() external isAuthorized {
        globalSettlement.shutdownSystem();
    }
}
