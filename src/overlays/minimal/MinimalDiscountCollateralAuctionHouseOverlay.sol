pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract DiscountCollateralAuctionHouseLike {
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, address) virtual external;
}
contract MinimalDiscountCollateralAuctionHouseOverlay is GebAuth {
    uint256                            public discountLimit;
    uint256                            public constant WAD = 10 ** 18;

    DiscountCollateralAuctionHouseLike public auctionHouse;

    constructor(address auctionHouse_, uint256 discountLimit_) public GebAuth() {
        require(auctionHouse_ != address(0), "MinimalDiscountCollateralAuctionHouseOverlay/null-address");
        require(both(discountLimit_ > 0, discountLimit_ < WAD), "MinimalDiscountCollateralAuctionHouseOverlay/invalid-discount-limit");

        auctionHouse  = DiscountCollateralAuctionHouseLike(auctionHouse_);
        discountLimit = discountLimit_;
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /**
     * @notice Modify an uint256 parameter
     * @param parameter The name of the parameter to modify
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        require(
          either(either(parameter == "minDiscount", parameter == "maxDiscount"), parameter == "perSecondDiscountUpdateRate"),
          "MinimalDiscountCollateralAuctionHouseOverlay/modify-forbidden-param"
        );

        if (parameter == "maxDiscount") {
            require(data >= discountLimit, "MinimalDiscountCollateralAuctionHouseOverlay/invalid-max-discount");
        }

        auctionHouse.modifyParameters(parameter, data);
    }

    /*
    * @notice Modify the systemCoinOracle address
    * @param parameter Must be "systemCoinOracle"
    * @param data The new systemCoinOracle address
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "systemCoinOracle") {
          auctionHouse.modifyParameters(parameter, data);
        } else revert("MinimalDiscountCollateralAuctionHouseOverlay/modify-forbidden-param");
    }
}
