pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract SetterRelayerLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract MinimalSetterRelayerOverlay is GebAuth {
    SetterRelayerLike public relayer;

    constructor(address relayer_) public GebAuth() {
        require(relayer_ != address(0), "MinimalSetterRelayerOverlay/null-address");
        relayer = SetterRelayerLike(relayer_);
    }

    /*
    * @notice Modify the setter address inside the SetterRelayer
    * @param parameter Must be "setter"
    * @param data The new address for the setter
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "setter") {
          relayer.modifyParameters(parameter, data);
        } else revert("MinimalSetterRelayerOverlay/modify-forbidden-param");
    }
}
