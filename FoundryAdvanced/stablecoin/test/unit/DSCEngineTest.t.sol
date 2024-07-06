// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

    DeployDSC deployer;
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;
    HelperConfig helperConfig;

    address wethUsdPriceFeed;
    address weth;
    address wbtcUsdPriceFeed;
    address wbtc;

    address USER = makeAddr("USER");
    uint256 constant AMOUNT_COLLATERAL = 10 ether;
    uint256 constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 constant AMOUNT_TO_MINT = 100 ether;

    function setUp() external {
        deployer = new DeployDSC();

        (dsc, dscEngine, helperConfig) = deployer.run();

        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, wbtc,) = helperConfig.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    ////
    // Constructor test
    ////
    address[] tokenAddresses;
    address[] priceFeedAddresses;

    function testRevertsIfTokenAddressesLengthAndPriceFeedLengthIsNotEqual() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(wethUsdPriceFeed);
        priceFeedAddresses.push(wbtcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    function testRevertsIfDscAddressIsZero() public {
        vm.expectRevert(DSCEngine.DSCEngine__AddressMustBeDifferentThanZero.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(0));
    }

    ////
    // Price Tests
    ////

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dscEngine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function testGetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dscEngine.getTokenAmountFromUsd(weth, usdAmount);

        assertEq(expectedWeth, actualWeth);
    }

    ////
    // Deposit Collateral Tests
    ////
    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("RAN", "RAN", USER, STARTING_ERC20_BALANCE);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__CollateralTokenNotAllowed.selector);
        dscEngine.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    modifier depositedCollateralAndMintDSC() {
        uint256 amountToMint = 100;
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        dscEngine.mintDSC(amountToMint);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDSCMinted, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);

        uint256 expectedTotalDSCMinted = 0;
        uint256 expectedDepositAmount = dscEngine.getTokenAmountFromUsd(weth, collateralValueInUsd);

        assertEq(totalDSCMinted, expectedTotalDSCMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    ////
    // Redeem Collateral Tests
    ////
    function testRevertsIfAmountToRedeemIsZero() public depositedCollateral {
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscEngine.redeemCollateral(address(weth), 0);
    }

    function testCanRedeemDepositedCollateral() public depositedCollateral {
        vm.prank(USER);
        dscEngine.redeemCollateral(address(weth), AMOUNT_COLLATERAL);

        uint256 expectedUserCollateralValue = 0;
        uint256 expectedUserAmount = AMOUNT_COLLATERAL;

        assertEq(expectedUserCollateralValue, dscEngine.getAccountCollateralValue(USER));
        assertEq(expectedUserAmount, ERC20Mock(weth).balanceOf(USER));
    }

    function testEmitCollateralRedeemedWithCorrectArgs() public depositedCollateral {
        vm.prank(USER);
        vm.expectEmit(true, true, true, true, address(dscEngine));
        emit CollateralRedeemed(USER, USER, weth, AMOUNT_COLLATERAL);
        dscEngine.redeemCollateral(address(weth), AMOUNT_COLLATERAL);
    }

    ////
    // Mint DSC Test
    ////
    function testMustMintMoreThanZeroDsc() public {
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscEngine.mintDSC(0);
    }

    function testRevertIfTriesToMintButHealthFactorIsBroken() public depositedCollateral {
        // Deposited $20.000,000000000000000000
        // (20,000 * 50) / 100 = $1.000,0000000000000000000
        (, int256 price,,,) = MockV3Aggregator(wethUsdPriceFeed).latestRoundData();
        uint256 amountToMint =
            (AMOUNT_COLLATERAL * (uint256(price) * dscEngine.getAdditionalFeedPrecision())) / dscEngine.getPrecision();

        vm.startPrank(USER);
        uint256 expectedHealthFactor =
            dscEngine.calculateHealthFactor(amountToMint, dscEngine.getUsdValue(weth, AMOUNT_COLLATERAL));
        vm.expectRevert(
            abi.encodeWithSelector(DSCEngine.DSCEngine__HealthFactorIsBelowMin.selector, expectedHealthFactor)
        );
        dscEngine.mintDSC(amountToMint);
        vm.stopPrank();
    }

    ////
    // Burn DSC Test
    ////
    function testCanBurnDsc() public depositedCollateralAndMintDSC {
        uint256 userDscBeforeBurn = ERC20Mock(address(dsc)).balanceOf(USER);
        uint256 dscToBurn = 50;
        vm.startPrank(USER);
        ERC20Mock(address(dsc)).approve(address(dscEngine), dscToBurn);
        dscEngine.burnDSC(dscToBurn);
        vm.stopPrank();
        uint256 userDscAfterBurn = ERC20Mock(address(dsc)).balanceOf(USER);

        assertEq(userDscBeforeBurn - dscToBurn, userDscAfterBurn);
    }

    ////
    // Health Factor Test
    ////
    function testReturnsMaxHealthFactorIfNoDSCMinted() public view {
        uint256 dscMinted = 0;
        uint256 collateralValue = 150;

        uint256 healthFactor = dscEngine.calculateHealthFactor(dscMinted, collateralValue);

        assertEq(type(uint256).max, healthFactor);
    }
}
