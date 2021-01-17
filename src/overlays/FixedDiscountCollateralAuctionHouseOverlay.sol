pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract FixedDiscountCollateralAuctionHouseLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract FixedDiscountCollateralAuctionHouseOverlay is GebAuth {
    FixedDiscountCollateralAuctionHouseLike public auctionHouse;

    constructor(address auctionHouse_) public GebAuth() {
        require(auctionHouse_ != address(0), "FixedDiscountCollateralAuctionHouseOverlay/null-address");
        auctionHouse = FixedDiscountCollateralAuctionHouseLike(auctionHouse_);
    }

    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "systemCoinOracle") {
          auctionHouse.modifyParameters(parameter, data);
        } else revert("FixedDiscountCollateralAuctionHouseOverlay/modify-forbidden-param");
    }
}
