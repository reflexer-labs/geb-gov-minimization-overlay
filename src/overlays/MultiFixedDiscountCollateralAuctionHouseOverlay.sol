pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract FixedDiscountCollateralAuctionHouseLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract MultiFixedDiscountCollateralAuctionHouseOverlay is GebAuth {
    mapping(address => uint256) public collateralAuctionHouses;

    constructor(address[] memory collateralAuctionHouses_) public GebAuth() {
        require(collateralAuctionHouses_.length > 0, "MultiFixedDiscountCollateralAuctionHouseOverlay/null-array");
        for (uint i = 0; i < collateralAuctionHouses_.length; i++) {
            require(collateralAuctionHouses_[i] != address(0), "MultiFixedDiscountCollateralAuctionHouseOverlay/null-address");
            collateralAuctionHouses[collateralAuctionHouses_[i]] = 1;
        }
    }

    function modifyParameters(address collateralAuctionHouse, bytes32 parameter, address data) external isAuthorized {
        require(collateralAuctionHouses[collateralAuctionHouse] == 1, "MultiFixedDiscountCollateralAuctionHouseOverlay/not-whitelisted");
        if (parameter == "systemCoinOracle") {
          FixedDiscountCollateralAuctionHouseLike(collateralAuctionHouse).modifyParameters(parameter, data);
        } else revert("FixedDiscountCollateralAuctionHouseOverlay/modify-forbidden-param");
    }
}
