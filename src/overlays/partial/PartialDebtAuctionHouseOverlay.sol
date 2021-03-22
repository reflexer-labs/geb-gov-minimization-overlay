pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract DebtAuctionHouseLike {
    function modifyParameters(bytes32, uint256) virtual external;
}

contract PartialDebtAuctionHouseOverlay is GebAuth {
    // --- Variables ---
    DebtAuctionHouseLike public debtAuctionHouse;

    constructor(address debtAuctionHouse_) public GebAuth() {
        require(debtAuctionHouse_ != address(0), "PartialSAFEEngineOverlay/null-debt-auction-house");
        debtAuctionHouse = DebtAuctionHouseLike(debtAuctionHouse_);
    }

    // --- Core Logic ---
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        debtAuctionHouse.modifyParameters(parameter, val);
    }
}
