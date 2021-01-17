pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract TaxCollectorLike {
    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) virtual external;
}
contract TaxCollectorOverlay is GebAuth {
    // --- Variables ---
    mapping(bytes32 => Bounds) public stabilityFeeBounds;
    TaxCollectorLike           public taxCollector;

    // --- Structs ---
    struct Bounds {
        uint256 upperBound;
        uint256 lowerBound;
    }

    constructor(
      address taxCollector_,
      bytes32[] memory collateralTypes,
      uint256[] memory lowerBounds,
      uint256[] memory upperBounds
    ) public {
        require(taxCollector_ != address(0), "TaxCollectorOverlay/null-address");
        require(both(collateralTypes.length == lowerBounds.length, lowerBounds.length == upperBounds.length), "TaxCollectorOverlay/invalid-array-lengths");
        require(collateralTypes.length > 0, "TaxCollectorOverlay/null-array-lengths");

        taxCollector = TaxCollectorLike(taxCollector_);

        for (uint i = 0; i < collateralTypes.length; i++) {
            require(
              both(stabilityFeeBounds[collateralTypes[i]].upperBound == 0, stabilityFeeBounds[collateralTypes[i]].lowerBound == 0),
              "TaxCollectorOverlay/bounds/already-set"
            );
            require(both(lowerBounds[i] >= RAY, upperBounds[i] > lowerBounds[i]), "TaxCollectorOverlay/invalid-bounds");
            stabilityFeeBounds[collateralTypes[i]] = Bounds(upperBounds[i], lowerBounds[i]);
        }
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Math ---
    uint256 public constant RAY = 10 ** 27;

    function modifyParameters(
        bytes32 collateralType,
        bytes32 parameter,
        uint256 data
    ) external {
        uint256 lowerBound = stabilityFeeBounds[collateralType].lowerBound;
        uint256 upperBound = stabilityFeeBounds[collateralType].upperBound;
        require(
          both(upperBound > lowerBound, lowerBound >= RAY),
          "TaxCollectorOverlay/bounds/already-set"
        );
        require(both(data <= upperBound, data >= lowerBound), "TaxCollectorOverlay/fee-exceeds-bounds");
        require(parameter == "stabilityFee", "TaxCollectorOverlay/invalid-parameter");
        taxCollector.modifyParameters(collateralType, parameter, data);
    }
}
