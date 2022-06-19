pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract CollateralAuctionHouseLike {
    function terminateAuctionPrematurely(uint256 id) virtual external;
}
abstract contract SAFEEngineLike {
    function transferCollateral(bytes32,address,address,uint256) virtual external;
}

contract MinimalGeneralCollateralAuctionHouseOverlay is GebAuth {
    SAFEEngineLike             public safeEngine;
    CollateralAuctionHouseLike public collateralAuctionHouse;

    constructor(address safeEngine_, address collateralAuctionHouse_) public GebAuth() {
        require(collateralAuctionHouse_ != address(0), "MinimalGeneralCollateralAuctionHouseOverlay/null-address");
        require(safeEngine_ != address(0), "MinimalGeneralCollateralAuctionHouseOverlay/null-address");
        safeEngine             = SAFEEngineLike(safeEngine_);
        collateralAuctionHouse = CollateralAuctionHouseLike(collateralAuctionHouse_);
    }

    /*
    * @notify Terminate a collateral auction prematurely
    * @param id ID of the auction to settle
    */
    function terminateAuctionPrematurely(uint256 id) external isAuthorized {
        collateralAuctionHouse.terminateAuctionPrematurely(id);
    }

    /*
    * @notify Transfer internal collateral to another address
    * @param collateralType Collateral type transferred
    * @param dst Collateral destination
    * @param wad Amount of collateral transferred
    */
    function transferCollateral(
        bytes32 collateralType,
        address dst,
        uint256 wad
    ) external isAuthorized {
        safeEngine.transferCollateral(collateralType, address(this), dst, wad);
    }
}
