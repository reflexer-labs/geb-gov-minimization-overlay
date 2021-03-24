pragma solidity 0.6.7;

import "ds-test/test.sol";

import "geb/AccountingEngine.sol";
import "geb/SAFEEngine.sol";

import "../../overlays/partial/PartialAccountingEngineOverlay.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract User {
    function modifyParameters(PartialAccountingEngineOverlay overlay, bytes32 parameter, uint256 val) external {
        overlay.modifyParameters(parameter, val);
    }
    function modifyParameters(PartialAccountingEngineOverlay overlay, bytes32 parameter, address data) external {
        overlay.modifyParameters(parameter, data);
    }
}

contract StakingPool {
    function canPrintProtocolTokens() public view returns (bool) {
        return true;
    }
}

contract PartialAccountingEngineOverlayTest is DSTest {
    Hevm hevm;

    User user;
    StakingPool pool;

    AccountingEngine accountingEngine;
    SAFEEngine safeEngine;

    PartialAccountingEngineOverlay overlay;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        safeEngine = new SAFEEngine();
        accountingEngine = new AccountingEngine(address(safeEngine), address(0x1), address(0x2));

        overlay = new PartialAccountingEngineOverlay(address(accountingEngine));
        accountingEngine.addAuthorization(address(overlay));

        user = new User();
        pool = new StakingPool();
    }

    function test_setup() public {
        assertEq(address(overlay.accountingEngine()), address(accountingEngine));
        assertEq(overlay.authorizedAccounts(address(this)), 1);
    }
    function test_add_auth() public {
        overlay.addAuthorization(address(0x3));
        assertEq(overlay.authorizedAccounts(address(0x3)), 1);
    }
    function test_remove_auth() public {
        overlay.removeAuthorization(address(this));
        assertEq(overlay.authorizedAccounts(address(this)), 0);
    }
    function testFail_lastSurplusAuctionTime() public {
        overlay.modifyParameters("lastSurplusAuctionTime", now + 5 hours);
    }
    function testFail_extraSurplusIsTransferred() public {
        overlay.modifyParameters("extraSurplusIsTransferred", 1);
    }
    function testFail_postSettlementSurplusDrain() public {
        overlay.modifyParameters("postSettlementSurplusDrain", address(0x3));
    }
    function testFail_protocolTokenAuthority() public {
        overlay.modifyParameters("protocolTokenAuthority", address(0x4));
    }
    function testFail_surplusAuctionHouse() public {
        overlay.modifyParameters("surplusAuctionHouse", address(0x4));
    }
    function testFail_extraSurplusReceiver() public {
        overlay.modifyParameters("extraSurplusReceiver", address(0x4));
    }
    function testFail_debtAuctionHouse() public {
        overlay.modifyParameters("debtAuctionHouse", address(0x4));
    }
    function test_modifyParams_uint() public {
        overlay.modifyParameters("surplusBuffer", 1E45);
        assertEq(accountingEngine.surplusBuffer(), 1E45);
    }
    function testFail_modifyParams_uint_unauthed() public {
        user.modifyParameters(overlay, "surplusBuffer", 1E45);
    }
    function test_modifyParams_address() public {
        overlay.modifyParameters("systemStakingPool", address(pool));
        assertEq(address(accountingEngine.systemStakingPool()), address(pool));
    }
    function testFail_modifyParams_address_unauthed() public {
        user.modifyParameters(overlay, "systemStakingPool", address(pool));
    }
}
