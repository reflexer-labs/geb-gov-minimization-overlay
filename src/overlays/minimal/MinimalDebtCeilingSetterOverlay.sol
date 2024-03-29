pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract DebtCeilingSetterLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalDebtCeilingSetterOverlay is GebAuth {
    DebtCeilingSetterLike public ceilingSetter;

    constructor(address ceilingSetter_) public GebAuth() {
        require(ceilingSetter_ != address(0), "MinimalDebtCeilingSetterOverlay/null-address");
        ceilingSetter = DebtCeilingSetterLike(ceilingSetter_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /*
    * @notify Modify the blockIncreaseWhenRevalue or blockDecreaseWhenDevalue value inside the ceiling setter
    * @param parameter Must be "blockIncreaseWhenRevalue" or "blockDecreaseWhenDevalue"
    * @param data The new value for blockIncreaseWhenRevalue or blockDecreaseWhenDevalue
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (either(parameter == "blockIncreaseWhenRevalue", parameter == "blockDecreaseWhenDevalue")) {
          ceilingSetter.modifyParameters(parameter, data);
        } else revert("MinimalDebtCeilingSetterOverlay/modify-forbidden-param");
    }
}
