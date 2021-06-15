pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract IncreasingTreasuryReimbursementLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalIncreasingTreasuryReimbursementOverlay is GebAuth {
    // --- Variables ---
    mapping(address => uint256) public reimbursers;

    // --- Events ---
    event ToggleReimburser(address reimburser, uint256 whitelisted);

    constructor() public GebAuth() {}

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Administration ---
    /*
    * @notice Whitelist/blacklist a reimburser contract
    * @param reimburser The reimburser address
    */
    function toggleReimburser(address reimburser) external isAuthorized {
        if (reimbursers[reimburser] == 0) {
          reimbursers[reimburser] = 1;
        } else {
          reimbursers[reimburser] = 0;
        }
        emit ToggleReimburser(reimburser, reimbursers[reimburser]);
    }

    /*
    * @notify Modify "baseUpdateCallerReward" or "maxUpdateCallerReward"
    * @param reimburser The reimburser address
    * @param parameter Must be "baseUpdateCallerReward" or "maxUpdateCallerReward"
    * @param data The new value for baseUpdateCallerReward or maxUpdateCallerReward
    */
    function modifyParameters(address reimburser, bytes32 parameter, uint256 data) external isAuthorized {
        require(reimbursers[reimburser] == 1, "MinimalIncreasingTreasuryReimbursementOverlay/not-whitelisted");
        if (either(parameter == "baseUpdateCallerReward", parameter == "maxUpdateCallerReward")) {
          IncreasingTreasuryReimbursementLike(reimburser).modifyParameters(parameter, data);
        } else revert("MinimalIncreasingTreasuryReimbursementOverlay/modify-forbidden-param");
    }
}
