pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract CollateralAuctionHouseLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract MultiCollateralAuctionHouseOverlay is GebAuth {
    mapping(address => uint256) public collateralAuctionHouses;

    constructor(address[] memory collateralAuctionHouses_) public GebAuth() {
        require(collateralAuctionHouses_.length > 0, "MultiCollateralAuctionHouseOverlay/null-array");
        for (uint i = 0; i < collateralAuctionHouses_.length; i++) {
            require(collateralAuctionHouses_[i] != address(0), "MultiCollateralAuctionHouseOverlay/null-address");
            collateralAuctionHouses[collateralAuctionHouses_[i]] = 1;
        }
    }

    function modifyParameters(address collateralAuctionHouse, bytes32 parameter, address data) external isAuthorized {
        require(collateralAuctionHouses[collateralAuctionHouse] == 1, "MultiCollateralAuctionHouseOverlay/not-whitelisted");
        if (parameter == "systemCoinOracle") {
          CollateralAuctionHouseLike(collateralAuctionHouse).modifyParameters(parameter, data);
        } else revert("MultiCollateralAuctionHouseOverlay/modify-forbidden-param");
    }
}
