pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/single/AccountingEngine.sol";
import "../../overlays/minimal/MinimalAccountingEngineOverlay.sol";

contract SimpleStakingPool {
    function canPrintProtocolTokens() public view returns (bool) {
        return true;
    }
}
contract User {
    function doModifyParameters(MinimalAccountingEngineOverlay overlay, bytes32 parameter, address addr) public {
        overlay.modifyParameters(parameter, addr);
    }
}
contract SimpleSAFEEngine {
    function approveSAFEModification(address account) external {}
}

contract MinimalAccountingEngineOverlayTest is DSTest {
    AccountingEngine accountingEngine;
    SimpleStakingPool staking;
    SimpleSAFEEngine safeEngine;
    MinimalAccountingEngineOverlay overlay;
    User user;

    function setUp() public {
        safeEngine       = new SimpleSAFEEngine();
        accountingEngine = new AccountingEngine(address(safeEngine), address(0x1), address(0x1));
        overlay          = new MinimalAccountingEngineOverlay(address(accountingEngine));
        staking          = new SimpleStakingPool();
        user             = new User();

        accountingEngine.addAuthorization(address(overlay));
    }

    function test_setup() public {
        assertEq(address(overlay.accountingEngine()), address(accountingEngine));
    }
    function test_add_auth() public {
        overlay.addAuthorization(address(0x3));
        assertEq(overlay.authorizedAccounts(address(0x3)), 1);
    }
    function test_remove_auth() public {
        overlay.addAuthorization(address(this));
        overlay.removeAuthorization(address(this));
        assertEq(overlay.authorizedAccounts(address(this)), 0);
    }
    function test_set_staking_pool() public {
        overlay.modifyParameters("systemStakingPool", address(staking));
        assertEq(address(accountingEngine.systemStakingPool()), address(staking));
    }
    function testFail_set_staking_pool_unauthed() public {
        user.doModifyParameters(overlay, "systemStakingPool", address(staking));
    }
    function testFail_set_other_param() public {
        overlay.modifyParameters("debtAuctionHouse", address(staking));
    }
}
