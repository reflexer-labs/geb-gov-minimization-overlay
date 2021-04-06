pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract CollateralAuctionHouseLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract MinimalMultiCollateralAuctionHouseOverlay is GebAuth {
    constructor() public GebAuth() {}

    /*
    * @notify Change the address of the systemCoinOracle inside a collateral auction house contract
    * @param collateralAuctionHouse The collateral auction house contract for which we change the systemCoinOracle address for
    * @param parameter Must be "systemCoinOracle"
    * @param data The new address for the systemCoinOracle
    */
    function modifyParameters(address collateralAuctionHouse, bytes32 parameter, address data) external isAuthorized {
        if (parameter == "systemCoinOracle") {
          CollateralAuctionHouseLike(collateralAuctionHouse).modifyParameters(parameter, data);
        } else revert("MinimalMultiCollateralAuctionHouseOverlay/modify-forbidden-param");
    }
}
