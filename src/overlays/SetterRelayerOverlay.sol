pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract SetterRelayerLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract SetterRelayerOverlay is GebAuth {
    SetterRelayerLike public relayer;

    constructor(address relayer_) public GebAuth() {
        require(relayer_ != address(0), "SetterRelayerOverlay/null-address");
        relayer = SetterRelayerLike(relayer_);
    }

    /*
    * @notice Modify the setter address inside the SetterRelayer
    * @param parameter Must be "setter"
    * @param data The new address for the setter
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "setter") {
          accountingEngine.modifyParameters(parameter, data);
        } else revert("SetterRelayerOverlay/modify-forbidden-param");
    }
}
