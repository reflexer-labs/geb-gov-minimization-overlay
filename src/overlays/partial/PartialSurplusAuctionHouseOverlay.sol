pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract SurplusAuctionHouseLike {
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, address) virtual external;
}

contract PartialSurplusAuctionHouseOverlay is GebAuth {
    // --- Variables ---
    SurplusAuctionHouseLike public surplusAuctionHouse;

    constructor(address surplusAuctionHouse_) public GebAuth() {
        require(surplusAuctionHouse_ != address(0), "PartialSAFEEngineOverlay/null-surplus-auction-house");
        surplusAuctionHouse = SurplusAuctionHouseLike(surplusAuctionHouse_);
    }

    // --- Core Logic ---
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        surplusAuctionHouse.modifyParameters(parameter, val);
    }

    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        surplusAuctionHouse.modifyParameters(parameter, data);
    }
}
