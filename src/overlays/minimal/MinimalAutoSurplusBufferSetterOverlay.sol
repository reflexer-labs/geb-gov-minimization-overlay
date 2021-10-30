pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract AutoSurplusBufferSetterLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalAutoSurplusBufferSetterOverlay is GebAuth {
    AutoSurplusBufferSetterLike public autoSurplusBuffer;

    constructor(address autoSurplusBuffer_) public GebAuth() {
        require(autoSurplusBuffer_ != address(0), "MinimalAutoSurplusBufferSetterOverlay/null-address");
        autoSurplusBuffer = AutoSurplusBufferSetterLike(autoSurplusBuffer_);
    }

    /*
    * @notify Change the stopAdjustments value
    * @param parameter Must be "stopAdjustments"
    * @param data The new value for stopAdjustments
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "stopAdjustments") {
          autoSurplusBuffer.modifyParameters(parameter, data);
        }
        else revert("MinimalAutoSurplusBufferSetterOverlay/modify-forbidden-param");
    }
}
