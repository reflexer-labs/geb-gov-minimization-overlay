pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract IncreasingTreasuryRelayerLike {
    function modifyParameters(bytes32, address) virtual external;
}
contract MinimalIncreasingTreasuryRelayerOverlay is GebAuth {
    // --- Variables ---
    mapping(address => uint256) public relayers;

    // --- Events ---
    event ToggleRelayer(address relayer, uint256 whitelisted);

    constructor() public GebAuth() {}

    // --- Administration ---
    /*
    * @notice Whitelist/blacklist a relayer contract
    * @param relayer The relayer address
    */
    function toggleRelayer(address relayer) external isAuthorized {
        if (relayers[relayer] == 0) {
          relayers[relayer] = 1;
        } else {
          relayers[relayer] = 0;
        }
        emit ToggleRelayer(relayer, relayers[relayer]);
    }

    /*
    * @notify Modify "refundRequestor"
    * @param relayer The relayer address
    * @param parameter Must be "refundRequestor"
    * @param data The new value for refundRequestor
    */
    function modifyParameters(address relayer, bytes32 parameter, address data) external isAuthorized {
        require(relayers[relayer] == 1, "MinimalIncreasingTreasuryRelayerOverlay/not-whitelisted");
        if (parameter == "refundRequestor") {
          IncreasingTreasuryRelayerLike(relayer).modifyParameters(parameter, data);
        } else revert("MinimalIncreasingTreasuryRelayerOverlay/modify-forbidden-param");
    }
}
