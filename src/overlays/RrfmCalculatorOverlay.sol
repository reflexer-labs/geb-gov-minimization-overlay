pragma solidity 0.6.7;

import "../auth/GebAuth.sol";

abstract contract RrfmCalculatorLike {
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, int256) virtual external;
}
contract RrfmCalculatorOverlay is GebAuth {
    // --- Vars ---
    mapping(bytes32 => UnsignedBounds) public unsignedBounds;
    mapping(bytes32 => SignedBounds)   public signedBounds;

    RrfmCalculatorLike public calculator;

    // --- Structs ---
    struct UnsignedBounds {
        uint256 upperBound;
        uint256 lowerBound;
    }
    struct SignedBounds {
        int256 upperBound;
        int256 lowerBound;
    }

    constructor(
        address calculator_,
        bytes32[] memory unsignedParams,
        bytes32[] memory signedParams,
        uint256[] memory unsignedUpperBounds,
        uint256[] memory unsignedLowerBounds,
        int256[] memory signedUpperBounds,
        int256[] memory signedLowerBounds
    ) public {
        require(
          both(unsignedParams.length == unsignedUpperBounds.length, unsignedParams.length == unsignedLowerBounds.length),
          "RrfmCalculatorOverlay/invalid-unsigned-lengths"
        );
        require(
          both(signedParams.length == signedUpperBounds.length, signedParams.length == signedLowerBounds.length),
          "RrfmCalculatorOverlay/invalid-signed-lengths"
        );
        require(calculator_ != address(0), "RrfmCalculatorOverlay/null-calculator");

        uint256 i;
        for (i = 0; i < unsignedParams.length; i++) {
            require(either(unsignedUpperBounds[i] != 0, unsignedLowerBounds[i] != 0), "RrfmCalculatorOverlay/invalid-uint-bounds");
            require(unsignedUpperBounds[i] >= unsignedLowerBounds[i], "RrfmCalculatorOverlay/incorrect-uint-bounds");
            unsignedBounds[unsignedParams[i]] = UnsignedBounds(unsignedUpperBounds[i], unsignedLowerBounds[i]);
        }
        for (i = 0; i < signedParams.length; i++) {
            require(either(signedUpperBounds[i] != 0, signedLowerBounds[i] != 0), "RrfmCalculatorOverlay/invalid-int-bounds");
            require(signedUpperBounds[i] >= signedLowerBounds[i], "RrfmCalculatorOverlay/incorrect-int-bounds");
            signedBounds[signedParams[i]] = SignedBounds(signedUpperBounds[i], signedLowerBounds[i]);
        }

        calculator = RrfmCalculatorLike(calculator_);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        UnsignedBounds memory bounds = unsignedBounds[parameter];

        if (parameter == "allReaderToggle") {
            calculator.modifyParameters(parameter, uint(1));
        }
        else if (either(bounds.upperBound != 0, bounds.lowerBound != 0)) {
            require(both(val >= bounds.lowerBound, val <= bounds.upperBound), "RrfmCalculatorOverlay/invalid-value");
            calculator.modifyParameters(parameter, val);
        }
        else revert("RrfmCalculatorOverlay/modify-forbidden-param");
    }

    function modifyParameters(bytes32 parameter, int256 val) external isAuthorized {
        SignedBounds memory bounds = signedBounds[parameter];

        if (parameter == "pdc") {
            calculator.modifyParameters(parameter, int(0));
        }
        else if (either(bounds.upperBound != 0, bounds.lowerBound != 0)) {
            require(both(val >= bounds.lowerBound, val <= bounds.upperBound), "RrfmCalculatorOverlay/invalid-value");
            calculator.modifyParameters(parameter, val);
        }
        else revert("RrfmCalculatorOverlay/modify-forbidden-param");
    }
}
