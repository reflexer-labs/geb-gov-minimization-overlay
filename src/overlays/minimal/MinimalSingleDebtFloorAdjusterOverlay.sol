pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract SingleDebtFloorAdjusterLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalSingleDebtFloorAdjusterOverlay is GebAuth {
    SingleDebtFloorAdjusterLike public adjuster;

    constructor(address adjuster_) public GebAuth() {
        require(adjuster_ != address(0), "MinimalSingleDebtFloorAdjusterOverlay/null-address");
        adjuster = SingleDebtFloorAdjusterLike(adjuster_);
    }

    /*
    * @notify Modify "lastUpdateTime"
    * @param parameter Must be "lastUpdateTime"
    * @param data The new value for lastUpdateTime
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "lastUpdateTime") {
          require(data >= block.timestamp, "MinimalSingleDebtFloorAdjusterOverlay/invalid-data");
          adjuster.modifyParameters(parameter, data);
        } else revert("MinimalSingleDebtFloorAdjusterOverlay/modify-forbidden-param");
    }
}
