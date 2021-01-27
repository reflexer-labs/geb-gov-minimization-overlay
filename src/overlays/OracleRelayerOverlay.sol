pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract OracleRelayerLike {
    function modifyParameters(bytes32, uint256) virtual external;
    function redemptionPrice() virtual public returns (uint256);
}
contract OracleRelayerOverlay is GebAuth {
    OracleRelayerLike public oracleRelayer;
    uint256           public constant RAY = 10 ** 27;

    constructor(address oracleRelayer_) public GebAuth() {
        require(oracleRelayer_ != address(0), "OracleRelayerOverlay/null-address");
        oracleRelayer = OracleRelayerLike(oracleRelayer_);
    }

    function restartRedemptionRate() external isAuthorized {
        oracleRelayer.redemptionPrice();
        oracleRelayer.modifyParameters("redemptionRate", RAY);
    }
}
