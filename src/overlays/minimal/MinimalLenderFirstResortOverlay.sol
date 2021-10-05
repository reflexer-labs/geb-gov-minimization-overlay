pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract GebLenderFirstResortRewardsLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalLenderFirstResortOverlay is GebAuth {
    GebLenderFirstResortRewards public staking;

    // Max amount of staked tokens to keep
    uint256                     public maxStakedTokensToKeep;

    constructor(address staking_, uint256 maxStakedTokensToKeep_) public GebAuth() {
        require(staking_ != address(0), "MinimalLenderFirstResortOverlay/null-address");
        require(maxStakedTokensToKeep_ > 0, "MinimalLenderFirstResortOverlay/null-maxStakedTokensToKeep");
        staking               = GebLenderFirstResortRewards(staking_);
        maxStakedTokensToKeep = maxStakedTokensToKeep_;
    }

    /*
    * @notify Modify escrowPaused
    * @param parameter Must be "escrowPaused"
    * @param data The new value for escrowPaused
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "escrowPaused") {
          staking.modifyParameters(parameter, data);
        }
        else revert("MinimalLenderFirstResortOverlay/modify-forbidden-param");
    }
}
