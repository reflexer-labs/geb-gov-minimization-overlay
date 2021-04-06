pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalDebtAuctionInitialParameterSetterOverlay} from "../../overlays/minimal/MinimalDebtAuctionInitialParameterSetterOverlay.sol";

contract User {
    function doModifyParameters(MinimalDebtAuctionInitialParameterSetterOverlay overlay, bytes32 parameter, address addr) public {
        overlay.modifyParameters(parameter, addr);
    }
}
contract DebtAuctionInitialParameterSetter {
    address public protocolTokenOrcl;
    address public systemCoinOrcl;

    function modifyParameters(bytes32 parameter, address addr) public {
        if (parameter == "protocolTokenOrcl") protocolTokenOrcl = addr;
        else if (parameter == "systemCoinOrcl") systemCoinOrcl = addr;
    }
}

contract MinimalDebtAuctionInitialParameterSetterOverlayTest is DSTest {
    User user;
    DebtAuctionInitialParameterSetter setter;
    MinimalDebtAuctionInitialParameterSetterOverlay overlay;

    function setUp() public {
        user     = new User();
        setter   = new DebtAuctionInitialParameterSetter();
        overlay  = new MinimalDebtAuctionInitialParameterSetterOverlay(address(setter));
    }

    function test_setup() public {
        assertEq(address(overlay.debtAuctionParamSetter()), address(setter));
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
    function test_set_prot_oracle() public {
        overlay.modifyParameters("protocolTokenOrcl", address(0x1));
        assertEq(setter.protocolTokenOrcl(), address(0x1));
    }
    function test_set_sys_coin_oracle() public {
        overlay.modifyParameters("systemCoinOrcl", address(0x1));
        assertEq(setter.systemCoinOrcl(), address(0x1));
    }
    function testFail_set_prot_token_by_unauthed() public {
        user.doModifyParameters(overlay, "protocolTokenOrcl", address(0x1));
    }
    function testFail_set_other_param() public {
        overlay.modifyParameters("accountingEngine", address(0x1));
    }
}
