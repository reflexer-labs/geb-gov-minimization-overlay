pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract RateSetterLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract RateSetterOverlay is GebAuth {
    RateSetterLike public rateSetter;

    constructor(address rateSetter_) public {
        require(rateSetter_ != address(0), "RateSetterOverlay/null-address");
        rateSetter = RateSetterLike(rateSetter_);
    }

    /*
    * @notify Change the orcl address inside the rate setter
    * @param parameter Must be "orcl"
    * @param data The new address for the orcl
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(parameter == "orcl", "RateSetterOverlay/modify-forbidden-param");
        rateSetter.modifyParameters(parameter, data);
    }
}
