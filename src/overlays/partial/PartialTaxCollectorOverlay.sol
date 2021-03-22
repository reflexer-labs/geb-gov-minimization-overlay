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
    function initializeCollateralType(bytes32 collateralType) external {
        taxCollector.initializeCollateralType(collateralType);
    }

    function modifyParameters(bytes32 collateralType, bytes32 parameter, uint256 val) external {
        taxCollector.modifyParameters(collateralType, parameter, val);
    }

    function modifyParameters(bytes32 parameter, uint256 val) external {
        taxCollector.modifyParameters(parameter, val);
    }

    function modifyParameters(bytes32 collateralType, uint256 position, uint256 val) external {
        taxCollector.modifyParameters(collateralType, position, val);
    }

    function modifyParameters(bytes32 collateralType, uint256 position, uint256 taxPercentage, address receiverAccount) external {
        taxCollector.modifyParameters(collateralType, position, taxPercentage, receiverAccount);
        require(
          taxCollector.secondaryReceiverAllotedTax(collateralType) <= secondaryReceiversMaxAllotedTax,
          "PartialTaxCollectorOverlay/invalid-secondary-receiver-tax"
        );
    }
}
