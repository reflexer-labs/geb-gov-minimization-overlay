pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract CollateralAuctionHouseLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract MultiCollateralAuctionHouseOverlay is GebAuth {
    constructor() public GebAuth() {}

    function modifyParameters(address collateralAuctionHouse, bytes32 parameter, address data) external isAuthorized {
        if (parameter == "systemCoinOracle") {
          CollateralAuctionHouseLike(collateralAuctionHouse).modifyParameters(parameter, data);
        } else revert("MultiCollateralAuctionHouseOverlay/modify-forbidden-param");
    }
}
