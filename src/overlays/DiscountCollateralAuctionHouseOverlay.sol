pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract DiscountCollateralAuctionHouseLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract DiscountCollateralAuctionHouseOverlay is GebAuth {
    DiscountCollateralAuctionHouseLike public auctionHouse;

    constructor(address auctionHouse_) public GebAuth() {
        require(auctionHouse_ != address(0), "DiscountCollateralAuctionHouseOverlay/null-address");
        auctionHouse = DiscountCollateralAuctionHouseLike(auctionHouse_);
    }

    /*
    * @notice Modify the systemCoinOracle address
    * @param parameter Must be "systemCoinOracle"
    * @param data The new systemCoinOracle address
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "systemCoinOracle") {
          auctionHouse.modifyParameters(parameter, data);
        } else revert("DiscountCollateralAuctionHouseOverlay/modify-forbidden-param");
    }
}
