pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract OracleRelayerLike {
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(
      bytes32,
      bytes32,
      address
    ) virtual external;
    function redemptionPrice() virtual public returns (uint256);
}
contract OracleRelayerOverlay is GebAuth {
    OracleRelayerLike public oracleRelayer;
    uint256           public constant RAY = 10 ** 27;

    constructor(address oracleRelayer_) public GebAuth() {
        require(oracleRelayer_ != address(0), "OracleRelayerOverlay/null-address");
        oracleRelayer = OracleRelayerLike(oracleRelayer_);
    }

    function restartRedemptionRate(bytes32 parameter) external isAuthorized {
        if (parameter == "redemptionRate") {
          oracleRelayer.redemptionPrice();
          oracleRelayer.modifyParameters("redemptionRate", RAY);
        } else revert("OracleRelayerOverlay/modify-forbidden-param");
    }

    function modifyParameters(
      bytes32 collateralType,
      bytes32 parameter,
      address data
    ) external {
        require(parameter == "orcl", "OracleRelayerOverlay/modify-forbidden-param");
        oracleRelayer.modifyParameters(collateralType, parameter, data);
    }
}
