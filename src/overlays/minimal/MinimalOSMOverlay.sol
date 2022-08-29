pragma solidity 0.6.7;

import "../../auth/GebAuth.sol";

abstract contract OSMLike {
    function changePriceSource(address) external virtual;
}

// @notice: Contract allows swapping of trusted oracles directly, but imposes a delay when entrusting or deleting an oracle implementation.
contract MinimalOSMOverlay is GebAuth {
    enum ChangeType {Add, Remove, Replace}

    struct Change {
        ChangeType action;
        uint256 executionTimestamp;
        uint256 oracleIndex;
        address newOracle;
    }

    // OSM address
    OSMLike public immutable OSM;
    // Delay enforced before trusted oracle changes
    uint256 public immutable entrustOracleDelay;
    // Array of trusted oracles
    address[] public         trustedOracles;
    // Scheduled change
    Change public            scheduledChange;

    /*
    * @notice Constructor
    * @param osmAddress Address of the OSM contract
    * @param trustedOracles_ List of previously trusted oracles
    * @param entrustOracleDelay_ Delay enforced to make a new oracle trusted
    */
    constructor(address osmAddress, address[] memory trustedOracles_, uint256 entrustOracleDelay_) public GebAuth() {
        require(osmAddress != address(0), "MinimalOSMOverlay/invalid-osm-address");
        require(entrustOracleDelay_ > 0, "MinimalOSMOverlay/invalid-entrust-oracle-delay");

        OSM = OSMLike(osmAddress);

        // setup oracles
        for (uint256 i; i < trustedOracles_.length; i++) {
            require(trustedOracles_[i] != address(0), "MinimalOSMOverlay/null-trusted-oracle-address");
            trustedOracles.push(trustedOracles_[i]);
        }

        // delay
        entrustOracleDelay  = entrustOracleDelay_;
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MinimalOSMOverlay/add-uint-uint-overflow");
    }

    // -- Swap of trusted oracles --
    /*
    * @notice Swap oracles for another trusted implementation
    * @param oracleIndex The index of the oracle to be used
    */
    function swapOracle(uint256 oracleIndex) external isAuthorized {
        OSM.changePriceSource(trustedOracles[oracleIndex]);
    }

    // -- Trusted oracle implementations management --
    /*
    * @notice Schedules a change to modify the trusted oracle list
    * @param changeType The type of change (Enum ChangeType)
    * @param oracleIndex The index of the oracle to be deleted or replaced (ignored if adding an oracle)
    * @param newOracle Oracle implementation to be added or replace an oracle implementation (igonored if deleting an oracle)
    */
    function ScheduleChangeTrustedOracle(ChangeType changeType, uint256 oracleIndex, address newOracle) external isAuthorized {
        require(scheduledChange.executionTimestamp == 0, "MinimalOSMOverlay/only-one-change-allowed");
        if (changeType == ChangeType.Add || changeType == ChangeType.Replace)
            require(newOracle != address(0), "MinimalOSMOverlay/null-oracle");

        if (changeType == ChangeType.Remove || changeType == ChangeType.Replace)
            require(oracleIndex < trustedOracles.length, "MinimalOSMOverlay/invalid-oracle");

        scheduledChange = Change({
                action: changeType,
                executionTimestamp: addition(now, entrustOracleDelay),
                oracleIndex: oracleIndex,
                newOracle: newOracle
            });
    }

    /*
    * @notice Executes a change
    */
    function executeChange() external {
        require(scheduledChange.executionTimestamp > 0, "MinimalOSMOverlay/no-scheduled-change");
        require(scheduledChange.executionTimestamp <= now, "MinimalOSMOverlay/wait-more");

        if (scheduledChange.action == ChangeType.Add)
            trustedOracles.push(scheduledChange.newOracle);
        else if (scheduledChange.action == ChangeType.Replace)
            trustedOracles[scheduledChange.oracleIndex] = scheduledChange.newOracle;
        else if (scheduledChange.action == ChangeType.Remove) {
            if(scheduledChange.oracleIndex != trustedOracles.length - 1)
                trustedOracles[scheduledChange.oracleIndex] = trustedOracles[trustedOracles.length - 1];

            trustedOracles.pop();
        }

        delete scheduledChange;
    }

    /*
    * @notice Cancels a change before execution
    */
    function cancelChange() external isAuthorized {
        require(scheduledChange.executionTimestamp != 0, "MinimalOSMOverlay/no-scheduled-change");
        delete scheduledChange;
    }
}
