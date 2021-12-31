pragma solidity 0.6.7;

import "ds-test/test.sol";

import {MinimalLenderFirstResortOverlay} from "../../overlays/minimal/MinimalLenderFirstResortOverlay.sol";

contract User {
    function doModifyParameters(MinimalLenderFirstResortOverlay overlay, bytes32 parameter, uint256 data) public {
        overlay.modifyParameters(parameter, data);
    }
}
contract LenderFirstResort {
    uint256 public escrowPaused;
    uint256 public minStakedTokensToKeep;
    uint256 public bypassAuctions;
    uint256 public tokensToAuction;
    uint256 public systemCoinsToRequest;

    function modifyParameters(bytes32 parameter, uint256 data) public {
        if (parameter == "escrowPaused") escrowPaused = data;
        if (parameter == "minStakedTokensToKeep") minStakedTokensToKeep = data;
        if (parameter == "tokensToAuction") tokensToAuction = data;
        if (parameter == "systemCoinsToRequest") systemCoinsToRequest = data;
    }

    function toggleBypassAuctions() public {
        bypassAuctions = bypassAuctions == 0 ? 1 : 0;
    }
}

contract MinimalLenderFirstResortOverlayTest is DSTest {
    User user;
    LenderFirstResort staking;
    MinimalLenderFirstResortOverlay overlay;

    uint maxStakedTokensToKeep = 1000 ether;

    function setUp() public {
        user     = new User();
        staking  = new LenderFirstResort();
        overlay  = new MinimalLenderFirstResortOverlay(address(staking), maxStakedTokensToKeep);
    }

    function test_setup() public {
        assertEq(address(overlay.staking()), address(staking));
        assertEq(overlay.maxStakedTokensToKeep(), maxStakedTokensToKeep);
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
    function testFail_set_escrowPaused_unauthed() public {
        user.doModifyParameters(overlay, "escrowPaused", 1);
    }
    function testFail_set_random_var() public {
        overlay.modifyParameters("randomVar", 1);
    }
    function test_set_escrowPaused() public {
        overlay.modifyParameters("escrowPaused", 1);
        assertEq(staking.escrowPaused(), 1);
    }
    function test_set_minStakedTokensToKeep() public {
        overlay.modifyParameters("minStakedTokensToKeep", maxStakedTokensToKeep);
        assertEq(staking.minStakedTokensToKeep(), maxStakedTokensToKeep);
    }
    function testFail_set_minStakedTokensToKeep_over_max() public {
        overlay.modifyParameters("minStakedTokensToKeep", maxStakedTokensToKeep + 1);
    }
    function test_set_bypassAuctions() public {
        overlay.toggleBypassAuctions();
        assertEq(staking.bypassAuctions(), 1);
    }
    function test_set_tokensToAuction() public {
        overlay.modifyParameters("tokensToAuction", 1 ether);
        assertEq(staking.tokensToAuction(), 1 ether);
    }
    function test_set_systemCoinsToRequest() public {
        overlay.modifyParameters("systemCoinsToRequest", 100 ether);
        assertEq(staking.systemCoinsToRequest(), 100 ether);
    }
}
