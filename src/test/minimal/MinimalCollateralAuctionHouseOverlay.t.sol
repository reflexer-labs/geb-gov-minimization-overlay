pragma solidity 0.6.7;

import "ds-test/test.sol";
import {DSDelegateToken} from "ds-token/delegate.sol";

import {SAFEEngine} from "geb/single/SAFEEngine.sol";
import {IncreasingDiscountCollateralAuctionHouse} from "geb/single/CollateralAuctionHouse.sol";
import {OracleRelayer} from "geb/single/OracleRelayer.sol";

import {MinimalCollateralAuctionHouseOverlay} from "../../overlays/minimal/MinimalCollateralAuctionHouseOverlay.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract Guy {
    IncreasingDiscountCollateralAuctionHouse increasingDiscountCollateralAuctionHouse;

    constructor(
      IncreasingDiscountCollateralAuctionHouse increasingDiscountCollateralAuctionHouse_
    ) public {
        increasingDiscountCollateralAuctionHouse = increasingDiscountCollateralAuctionHouse_;
    }
    function approveSAFEModification(bytes32 auctionType, address safe) public {
        address safeEngine;
        safeEngine = address(increasingDiscountCollateralAuctionHouse.safeEngine());
        SAFEEngine(safeEngine).approveSAFEModification(safe);
    }
    function try_buyCollateral_increasingDiscount(uint id, uint wad)
        public returns (bool ok)
    {
        string memory sig = "buyCollateral(uint256,uint256)";
        (ok,) = address(increasingDiscountCollateralAuctionHouse).call(abi.encodeWithSignature(sig, id, wad));
    }
    function try_increasingDiscount_terminateAuctionPrematurely(uint id)
        public returns (bool ok)
    {
        string memory sig = "terminateAuctionPrematurely(uint256)";
        (ok,) = address(increasingDiscountCollateralAuctionHouse).call(abi.encodeWithSignature(sig, id));
    }
}

contract SAFEEngine_ is SAFEEngine {
    function mint(address usr, uint wad) public {
        coinBalance[usr] += wad;
    }
    function coin_balance(address usr) public view returns (uint) {
        return coinBalance[usr];
    }
    bytes32 collateralType;
    function set_collateral_type(bytes32 collateralType_) public {
        collateralType = collateralType_;
    }
    function token_collateral_balance(address usr) public view returns (uint) {
        return tokenCollateral[collateralType][usr];
    }
}

contract Feed {
    address public priceSource;
    uint256 public priceFeedValue;
    bool public hasValidValue;
    constructor(bytes32 initPrice, bool initHas) public {
        priceFeedValue = uint(initPrice);
        hasValidValue = initHas;
    }
    function set_val(uint newPrice) external {
        priceFeedValue = newPrice;
    }
    function set_price_source(address priceSource_) external {
        priceSource = priceSource_;
    }
    function set_has(bool newHas) external {
        hasValidValue = newHas;
    }
    function getResultWithValidity() external returns (uint256, bool) {
        return (priceFeedValue, hasValidValue);
    }
}

contract Gal {}

contract DummyLiquidationEngine {
    uint256 public currentOnAuctionSystemCoins;

    constructor(uint rad) public {
        currentOnAuctionSystemCoins = rad;
    }

    function subtract(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function removeCoinsFromAuction(uint rad) public {
      currentOnAuctionSystemCoins = subtract(currentOnAuctionSystemCoins, rad);
    }
}

contract MinimalCollateralAuctionHouseOverlayTest is DSTest {
    Hevm hevm;

    MinimalCollateralAuctionHouseOverlay overlay;

    DummyLiquidationEngine liquidationEngine;
    SAFEEngine_ safeEngine;
    IncreasingDiscountCollateralAuctionHouse collateralAuctionHouse;
    OracleRelayer oracleRelayer;
    Feed    collateralFSM;
    Feed    collateralMedian;
    Feed    systemCoinMedian;

    address ali;
    address bob;
    address auctionIncomeRecipient;
    address safeAuctioned = address(0xacab);

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    uint constant RAD = 10 ** 45;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        safeEngine = new SAFEEngine_();

        safeEngine.initializeCollateralType("collateralType");
        safeEngine.set_collateral_type("collateralType");

        liquidationEngine = new DummyLiquidationEngine(rad(1000 ether));
        collateralAuctionHouse = new IncreasingDiscountCollateralAuctionHouse(address(safeEngine), address(liquidationEngine), "collateralType");

        oracleRelayer = new OracleRelayer(address(safeEngine));
        oracleRelayer.modifyParameters("redemptionPrice", 5 * RAY);
        collateralAuctionHouse.modifyParameters("oracleRelayer", address(oracleRelayer));

        collateralFSM = new Feed(bytes32(uint256(0)), true);
        collateralAuctionHouse.modifyParameters("collateralFSM", address(collateralFSM));

        collateralMedian = new Feed(bytes32(uint256(0)), true);
        systemCoinMedian = new Feed(bytes32(uint256(0)), true);

        collateralFSM.set_price_source(address(collateralMedian));

        ali = address(new Guy(collateralAuctionHouse));
        bob = address(new Guy(collateralAuctionHouse));
        auctionIncomeRecipient = address(new Gal());

        Guy(ali).approveSAFEModification("increasing", address(collateralAuctionHouse));
        Guy(bob).approveSAFEModification("increasing", address(collateralAuctionHouse));
        safeEngine.approveSAFEModification(address(collateralAuctionHouse));

        safeEngine.modifyCollateralBalance("collateralType", address(this), 1000 ether);
        safeEngine.mint(ali, 200 ether);
        safeEngine.mint(bob, 200 ether);

        overlay = new MinimalCollateralAuctionHouseOverlay(address(safeEngine), address(collateralAuctionHouse));
        collateralAuctionHouse.addAuthorization(address(overlay));
    }

    // --- Math ---
    function rad(uint wad) internal pure returns (uint z) {
        z = wad * 10 ** 27;
    }
    function addition(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function subtract(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function wmultiply(uint x, uint y) internal pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }
    function rdivide(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division-by-zero");
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division-by-zero");
        z = multiply(x, WAD) / y;
    }

    function test_terminate_auction_from_overlay() public {
        oracleRelayer.modifyParameters("redemptionPrice", 2 * RAY);
        collateralFSM.set_val(200 ether);
        safeEngine.mint(ali, 200 * RAD - 200 ether);

        uint collateralAmountPreBid = safeEngine.tokenCollateral("collateralType", address(ali));

        uint id = collateralAuctionHouse.startAuction({ amountToSell: 1 ether
                                                      , amountToRaise: 50 * RAD
                                                      , forgoneCollateralReceiver: safeAuctioned
                                                      , auctionIncomeRecipient: auctionIncomeRecipient
                                                      , initialBid: 0
                                                      });

        assertEq(liquidationEngine.currentOnAuctionSystemCoins(), rad(1000 ether));

        overlay.terminateAuctionPrematurely(1);
        ( uint256 amountToSell,
          uint256 amountToRaise,
          ,
          ,
          ,
          ,
          ,
          ,
        ) = collateralAuctionHouse.bids(1);
        assertEq(amountToSell, 0);
        assertEq(amountToRaise, 0);
    }
    function testFail_unauthed_transfer_internal_collateral() public {
        safeEngine.modifyCollateralBalance("collateralType", address(overlay), 1000 ether);
        overlay.transferCollateral("collateralType", address(0x1), 100 ether);
        uint collateralAmount = safeEngine.tokenCollateral("collateralType", address(0x1));
        assertEq(collateralAmount, 100 ether);
    }
}
