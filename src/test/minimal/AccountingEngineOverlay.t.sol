pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/AccountingEngine.sol";
import "../../overlays/minimal/AccountingEngineOverlay.sol";

contract SimpleStakingPool {
    function canPrintProtocolTokens() public view returns (bool) {
        return true;
    }
}
contract User {
    function doModifyParameters(AccountingEngineOverlay overlay, bytes32 parameter, address addr) public {
        overlay.modifyParameters(parameter, addr);
    }
}
contract SimpleSAFEEngine {
    function approveSAFEModification(address account) external {}
}

contract AccountingEngineOverlayTest is DSTest {
    AccountingEngine accountingEngine;
    SimpleStakingPool staking;
    SimpleSAFEEngine safeEngine;
    AccountingEngineOverlay overlay;
    User user;

    function setUp() public {
        safeEngine       = new SimpleSAFEEngine();
        accountingEngine = new AccountingEngine(address(safeEngine), address(0x1), address(0x1));
        overlay          = new AccountingEngineOverlay(address(accountingEngine));
        staking          = new SimpleStakingPool();
        user             = new User();

        accountingEngine.addAuthorization(address(overlay));
    }

    function test_setup() public {
        assertEq(address(overlay.accountingEngine()), address(accountingEngine));
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
