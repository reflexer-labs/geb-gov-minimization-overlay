pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract RateSetterLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract MinimalRateSetterOverlay is GebAuth {
    RateSetterLike public rateSetter;

    constructor(address rateSetter_) public {
        require(rateSetter_ != address(0), "MinimalRateSetterOverlay/null-address");

        rateSetter   = RateSetterLike(rateSetter_);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /*
    * @notify Change address params
    * @param parameter The name of the parameter to change
    * @param data The new address for the orcl
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "orcl") {
          rateSetter.modifyParameters(parameter, data);
        } else revert("MinimalRateSetterOverlay/modify-forbidden-param");
    }
}
