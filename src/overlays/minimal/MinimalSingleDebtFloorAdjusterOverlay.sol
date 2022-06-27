pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract SingleDebtFloorAdjusterLike {
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, address) virtual external;
}
contract MinimalSingleDebtFloorAdjusterOverlay is GebAuth {
    SingleDebtFloorAdjusterLike public adjuster;

    constructor(address adjuster_) public GebAuth() {
        require(adjuster_ != address(0), "MinimalSingleDebtFloorAdjusterOverlay/null-address");
        adjuster = SingleDebtFloorAdjusterLike(adjuster_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /*
    * @notify Modify "lastUpdateTime"
    * @param parameter Must be "lastUpdateTime", "maxPriceDeviation" or "auctionDiscount"
    * @param data The new value for lastUpdateTime
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "lastUpdateTime") {
          require(data >= block.timestamp, "MinimalSingleDebtFloorAdjusterOverlay/invalid-data");
          adjuster.modifyParameters(parameter, data);
        } else if(either(parameter == "maxPriceDeviation", parameter == "auctionDiscount")) {
          adjuster.modifyParameters(parameter, data);
        }
        else revert("MinimalSingleDebtFloorAdjusterOverlay/modify-forbidden-param");
    }
    /*
    * @notify Modify address params
    * @param parameter The name of the parameter to change
    * @param addr The address to set the parameter to
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        if (either(parameter == "gasPriceOracle", parameter == "ethPriceOracle")) {
          adjuster.modifyParameters(parameter, addr);
        } else revert("MinimalSingleDebtFloorAdjusterOverlay/modify-forbidden-param");
    }
}
