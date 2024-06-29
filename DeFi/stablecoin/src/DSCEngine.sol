// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDSCEngine} from "./IDSCEngine.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author Daniel Tomé
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == 1$ peg.
 * This stablecoin has the properties:
 * - Exogenous collateral.
 * - Dollar pegged.
 * - Algoritmically stable (mint, burn).
 *
 * It is similar to DAI if DAI had no governance, no fees, and was only backed by WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of all collateral <= the $ backed value
 * of all the DSC.
 *
 * @notice This contract is the core of the DSC System. It handles all the logic for mining and redeeming DSC, as well as
 * depositing & withdrawing collateral. This conttract is VERY loosely base on the MarkerDAO DSS (DAI) System.
 */
contract DSCEngine is IDSCEngine, ReentrancyGuard {
    ////
    // Errors
    ////
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__CollateralTokenNotAllowed();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__AddressMustBeDifferentThanZero();
    error DSCEngine__TransferFailed();
    error DSCEngine__HealthFactorIsBelowMin(uint256 healthFactor);
    error DSCEngine__MintFailed();

    ////
    // State variables
    ////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10; // ETH and BTC has 1e8 precision decimals
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_dscMinted;

    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;

    ////
    // Events
    ////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

    ////
    // Modifiers
    ////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address tokenAddress) {
        if (s_priceFeeds[tokenAddress] == address(0)) {
            revert DSCEngine__CollateralTokenNotAllowed();
        }
        _;
    }

    ////
    // Functions
    ////

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        if (dscAddress == address(0)) revert DSCEngine__AddressMustBeDifferentThanZero();

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ////
    // External Functions
    ////
    function depositCollateralAndMintDSC() external {}

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    function mintDSC(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
        s_dscMinted[msg.sender] += amountDscToMint;
        // if they minted too much ($150 DSC from $100 ETH) -> revert
        _revertIfHealthFactorIsBroken(msg.sender);

        bool succed = i_dsc.mint(msg.sender, amountDscToMint);
        if (!succed) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    ////
    // Private & Internal View functions
    ////

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_dscMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);

        return (totalDscMinted, collateralValueInUsd);
    }

    /**
     * Returns how close to liquidation is.
     * If user goes below 1, then they can get liquidated.
     * @param user User address
     */
    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        // $150 ETH / 100 DSC = 1.5
        // 150 * 50 = 7500 / 100 = 75 -> (75 / 100(dsc)) < 1 => liquidate
        //
        // $1000 ETH / 100 DSC
        // 1000 * 50 = 50000 / 100 = (500 / 100) > 1 => OK
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorIsBelowMin(userHealthFactor);
        }
    }

    ////
    // Public & External View functions
    ////
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address collateralToken = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][collateralToken];
            // Check price in USD from amount.
            totalCollateralValueInUsd += getUsdValue(collateralToken, amount);
        }
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);

        (, int256 price,,,) = priceFeed.latestRoundData();

        uint256 usdValueFromAmount = amount * (uint256(price) * ADDITIONAL_FEED_PRECISION) / PRECISION;
        return usdValueFromAmount;
    }
}
