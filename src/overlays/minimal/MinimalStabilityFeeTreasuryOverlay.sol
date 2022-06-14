pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract StabilityFeeTreasuryLike {
    function setTotalAllowance(address, uint256) virtual external;
    function setPerBlockAllowance(address, uint256) virtual external;
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalStabilityFeeTreasuryOverlay is GebAuth {
    StabilityFeeTreasuryLike public treasury;

    constructor(address treasury_) public GebAuth() {
        require(treasury_ != address(0), "MinimalStabilityFeeTreasuryOverlay/null-address");
        treasury = StabilityFeeTreasuryLike(treasury_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /**
     * @notice Modify an address' total allowance in order to withdraw SF from the treasury
     * @param account The approved address
     * @param rad The total approved amount of SF to withdraw (number with 45 decimals)
     */
    function setTotalAllowance(address account, uint256 rad) external isAuthorized {
        treasury.setTotalAllowance(account, rad);
    }

    /**
     * @notice Modify an address' per block allowance in order to withdraw SF from the treasury
     * @param account The approved address
     * @param rad The per block approved amount of SF to withdraw (number with 45 decimals)
     */
    function setPerBlockAllowance(address account, uint256 rad) external isAuthorized {
        treasury.setPerBlockAllowance(account, rad);
    }

    /**
     * @notice Modify an uint256 param
     * @param parameter Parameter, any allowed
     * @param data The new value
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        treasury.modifyParameters(parameter, data);
    }
}
