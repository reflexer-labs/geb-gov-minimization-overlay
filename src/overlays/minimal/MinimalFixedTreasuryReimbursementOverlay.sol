pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract FixedTreasuryReimbursementLike {
    function modifyParameters(bytes32, uint256) virtual external;
}
contract MinimalFixedTreasuryReimbursementOverlay is GebAuth {
    FixedTreasuryReimbursementLike public reimburser;

    constructor(address reimburser_) public GebAuth() {
        require(reimburser_ != address(0), "MinimalFixedTreasuryReimbursementOverlay/null-address");
        reimburser = FixedTreasuryReimbursementLike(reimburser_);
    }

    /*
    * @notify Modify "fixedReward"
    * @param parameter Must be "fixedReward"
    * @param data The new value for the fixedReward
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "fixedReward") {
          reimburser.modifyParameters(parameter, data);
        } else revert("MinimalFixedTreasuryReimbursementOverlay/modify-forbidden-param");
    }
}
