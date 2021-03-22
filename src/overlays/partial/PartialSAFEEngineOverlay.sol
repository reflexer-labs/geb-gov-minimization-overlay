pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract SAFEEngineLike {
    function initializeCollateralType(bytes32) virtual external;
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, address) virtual external;
    function modifyParameters(bytes32, bytes32, uint256) virtual external;
    function modifyCollateralBalance(bytes32, address, int256) virtual external;
    function createUnbackedDebt(address,address,uint256) virtual external;
}

contract PartialSAFEEngineOverlay is GebAuth {
    // --- Authorization ---
    mapping (address => uint) public collateralJoins;
    /**
     * @notice Whitelist a collateral join contract
     * @param join Collateral join to whitelist
     */
    function addCollateralJoin(address join) external isAuthorized {
        collateralJoins[join] = 1;
        emit AddCollateralJoin(join);
    }
    /**
     * @notice Blacklist a collateral join contract
     * @param join Collateral join to blacklist
     */
    function removeCollateralJoin(address join) external isAuthorized {
        collateralJoins[join] = 0;
        emit RemoveCollateralJoin(join);
    }
    /**
    * @notice Checks whether msg.sender is a whitelisted collateral join
    **/
    modifier isCollateralJoin {
        require(collateralJoins[msg.sender] == 1, "PartialSAFEEngineOverlay/join-not-authorized");
        _;
    }

    // --- Variables ---
    SAFEEngineLike public safeEngine;

    // --- Events ---
    event AddCollateralJoin(address join);
    event RemoveCollateralJoin(address join);

    constructor(address safeEngine_) public GebAuth() {
        require(safeEngine_ != address(0), "PartialSAFEEngineOverlay/null-safe-engine");
        safeEngine = SAFEEngineLike(safeEngine_);
    }

    // --- Core Logic ---
    /**
     * @notice Creates a brand new collateral type
     * @param collateralType Collateral type name (e.g ETH-A, TBTC-B)
     */
    function initializeCollateralType(bytes32 collateralType) external isAuthorized {
        safeEngine.initializeCollateralType(collateralType);
    }
    /**
     * @notice Modify general uint256 params
     * @param parameter The name of the parameter modified
     * @param val New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        safeEngine.modifyParameters(parameter, val);
    }
    /**
     * @notice Modify collateral specific params
     * @param collateralType Collateral type we modify params for
     * @param parameter The name of the parameter modified
     * @param val New value for the parameter
     */
    function modifyParameters(bytes32 collateralType, bytes32 parameter, uint256 val) external isAuthorized {
        safeEngine.modifyParameters(collateralType, parameter, val);
    }
    /**
     * @notice Join/exit collateral into and and out of the system
     * @param collateralType Collateral type to join/exit
     * @param account Account that gets credited/debited
     * @param wad Amount of collateral
     */
    function modifyCollateralBalance(bytes32 collateralType, address account, int256 wad) external isCollateralJoin {
        safeEngine.modifyCollateralBalance(collateralType, account, wad);
    }
    /**
     * @notice Usually called by CoinSavingsAccount in order to create unbacked debt
     * @param debtDestination Usually AccountingEngine that can settle uncovered debt with surplus
     * @param coinDestination Usually CoinSavingsAccount that passes the new coins to depositors
     * @param rad Amount of debt to create
     */
    function createUnbackedDebt(address debtDestination, address coinDestination, uint256 rad) external isAuthorized {
        safeEngine.createUnbackedDebt(debtDestination, coinDestination, rad);
    }
}
