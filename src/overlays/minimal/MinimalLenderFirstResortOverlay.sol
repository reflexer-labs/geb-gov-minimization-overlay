pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract GebLenderFirstResortRewardsLike {
    function modifyParameters(bytes32, uint256) virtual external;
    function toggleBypassAuctions() virtual external;
    function toggleForcedExit() virtual external;
}
contract MinimalLenderFirstResortOverlay is GebAuth {
    GebLenderFirstResortRewardsLike public staking;

    // Max amount of staked tokens to keep
    uint256 public maxStakedTokensToKeep;

    constructor(address staking_, uint256 maxStakedTokensToKeep_) public GebAuth() {
        require(staking_ != address(0), "MinimalLenderFirstResortOverlay/null-address");
        require(maxStakedTokensToKeep_ > 0, "MinimalLenderFirstResortOverlay/null-maxStakedTokensToKeep");
        staking               = GebLenderFirstResortRewardsLike(staking_);
        maxStakedTokensToKeep = maxStakedTokensToKeep_;
    }

    /*
    * @notify Modify parameters
    * @param parameter Must be either minStakedTokensToKeep, escrowPaused, tokensToAuction or systemCoinsToRequest
    * @param data The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "minStakedTokensToKeep") {
            require(data <= maxStakedTokensToKeep, "MinimalLenderFirstResortOverlay/minStakedTokensToKeep-over-limit");
            staking.modifyParameters(parameter, data);
        } else if (
            parameter == "escrowPaused"    ||
            parameter == "tokensToAuction" ||
            parameter == "systemCoinsToRequest"
            ) staking.modifyParameters(parameter, data);
        else revert("MinimalLenderFirstResortOverlay/modify-forbidden-param");
    }

    /*
    * @notice Allow/disallow stakers to exit without extra checks
    */
    function toggleForcedExit() external isAuthorized {
        staking.toggleForcedExit();
    }

    /*
    * @notify Bypass Auctions
    */
    function toggleBypassAuctions() external isAuthorized {
        staking.toggleBypassAuctions();
    }
}
