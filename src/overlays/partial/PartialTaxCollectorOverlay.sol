pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract TaxCollectorLike {
    function WHOLE_TAX_CUT() virtual public view returns (uint256);
    function secondaryReceiverAllotedTax(bytes32) virtual public view returns (uint256);
    function initializeCollateralType(bytes32) virtual external;
    function modifyParameters(bytes32, bytes32, uint256) virtual external;
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, uint256, uint256) virtual external;
    function modifyParameters(bytes32, uint256, uint256, address) virtual external;
}

contract PartialTaxCollectorOverlay is GebAuth {
    // --- Variables ---
    uint256 public immutable secondaryReceiversMaxAllotedTax;

    TaxCollectorLike public taxCollector;

    constructor(address taxCollector_, uint256 secondaryReceiversMaxAllotedTax_) public GebAuth() {
        require(taxCollector_ != address(0), "PartialTaxCollectorOverlay/null-tax-collector");
        taxCollector = TaxCollectorLike(taxCollector_);

        require(
          both(secondaryReceiversMaxAllotedTax_ > 0, secondaryReceiversMaxAllotedTax_ < taxCollector.WHOLE_TAX_CUT()),
          "PartialTaxCollectorOverlay/invalid-max-alloted-tax"
        );
        secondaryReceiversMaxAllotedTax = secondaryReceiversMaxAllotedTax_;
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Core Logic ---
    /**
     * @notice Initialize a brand new collateral type
     * @param collateralType Collateral type name (e.g ETH-A, TBTC-B)
     */
    function initializeCollateralType(bytes32 collateralType) external {
        taxCollector.initializeCollateralType(collateralType);
    }
    /**
     * @notice Modify collateral specific uint256 params
     * @param collateralType Collateral type who's parameter is modified
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 collateralType, bytes32 parameter, uint256 val) external {
        taxCollector.modifyParameters(collateralType, parameter, val);
    }
    /**
     * @notice Modify general uint256 params
     * @param parameter The name of the parameter modified
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 val) external {
        taxCollector.modifyParameters(parameter, val);
    }
    /**
     * @notice Set whether a tax receiver can incur negative fees
     * @param collateralType Collateral type giving fees to the tax receiver
     * @param position Receiver position in the list
     * @param val Value that specifies whether a tax receiver can incur negative rates
     */
    function modifyParameters(bytes32 collateralType, uint256 position, uint256 val) external {
        taxCollector.modifyParameters(collateralType, position, val);
    }
    /**
     * @notice Create or modify a secondary tax receiver's data
     * @param collateralType Collateral type that will give SF to the tax receiver
     * @param position Receiver position in the list. Used to determine whether a new tax receiver is
              created or an existing one is edited
     * @param taxPercentage Percentage of SF offered to the tax receiver
     * @param receiverAccount Receiver address
     */
    function modifyParameters(bytes32 collateralType, uint256 position, uint256 taxPercentage, address receiverAccount) external {
        taxCollector.modifyParameters(collateralType, position, taxPercentage, receiverAccount);
        require(
          taxCollector.secondaryReceiverAllotedTax(collateralType) <= secondaryReceiversMaxAllotedTax,
          "PartialTaxCollectorOverlay/invalid-secondary-total-tax"
        );
    }
}
