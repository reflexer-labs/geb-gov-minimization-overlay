pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract StakedTokenAuctionHouseLike {
    function modifyParameters(bytes32, address) external virtual;
    function disableContract() external virtual;
}

contract MinimalStakedTokenAuctionHouseOverlay is GebAuth {
    StakedTokenAuctionHouseLike public auctionHouse;

    constructor(address auctionHouse_) public GebAuth() {
        require(auctionHouse_ != address(0), "MinimalStakedTokenAuctionHouseOverlay/null-address");
        auctionHouse = StakedTokenAuctionHouseLike(auctionHouse_);
    }

    /*
    * @notice Change the tokenBurner address in the auction house
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(parameter == "tokenBurner", "MinimalStakedTokenAuctionHouseOverlay/invalid-parameter");
        auctionHouse.modifyParameters(parameter, data);
    }

    /*
    * @notice Disable the auction house
    */
    function disableContract() external isAuthorized {
        auctionHouse.disableContract();
    }
}
