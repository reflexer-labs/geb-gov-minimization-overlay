pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract DebtAuctionInitialParameterSetterLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract MinimalDebtAuctionInitialParameterSetterOverlay is GebAuth {
    DebtAuctionInitialParameterSetterLike public debtAuctionParamSetter;

    constructor(address debtAuctionParamSetter_) public GebAuth() {
        require(debtAuctionParamSetter_ != address(0), "MinimalDebtAuctionInitialParameterSetterOverlay/null-address");
        debtAuctionParamSetter = DebtAuctionInitialParameterSetterLike(debtAuctionParamSetter_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /*
    * @notify Change the address of the protocolTokenOrcl or systemCoinOrcl inside the debtAuctionParamSetter
    * @param parameter Must be "protocolTokenOrcl" or "systemCoinOrcl"
    * @param data The new address for the protocolTokenOrcl or the systemCoinOrcl
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (either(parameter == "protocolTokenOrcl", parameter == "systemCoinOrcl")) {
            debtAuctionParamSetter.modifyParameters(parameter, data);
        }
        else revert("MinimalDebtAuctionInitialParameterSetterOverlay/modify-forbidden-param");
    }
}
