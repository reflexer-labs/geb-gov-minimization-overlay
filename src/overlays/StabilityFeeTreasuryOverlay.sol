pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract StabilityFeeTreasuryLike {
    function takeFunds(address, uint256) virtual external;
}
contract StabilityFeeTreasuryOverlay is GebAuth {
    StabilityFeeTreasuryLike public treasury;

    constructor(address treasury_) public GebAuth() {
        require(treasury_ != address(0), "StabilityFeeTreasuryOverlay/null-address");
        treasury = StabilityFeeTreasuryLike(treasury_);
    }

    function takeFunds(address account, uint256 amount) external isAuthorized {
        treasury.takeFunds(account, amount);
    }
}
