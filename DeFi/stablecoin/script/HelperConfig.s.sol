// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockAggregator} from "@chainlink/contracts/src/v0.8/mocks/MockAggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        uint256 deployerKey;
    }

    uint256 public constant DECIMALS = 8;
    uint256 public constant WETH_USD_PRICE = 2000e8;
    uint256 public constant WBTC_USD_PRICE = 1000e8;
    int256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() private view returns (NetworkConfig memory) {
        return NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() private returns (NetworkConfig memory) {
        if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockAggregator wethUsdPriceFeed = new MockAggregator();
        wethUsdPriceFeed.setLatestAnswer(WETH_USD_PRICE);
        MockAggregator wbtcUsdPriceFeed = new MockAggregator();
        wbtcUsdPriceFeed.setLatestAnswer(WBTC_USD_PRICE);

        ERC20Mock weth = new ERC20Mock("WETH", "WETH", msg.sender, 1000e8);
        ERC20Mock wbtc = new ERC20Mock("WBTC", "WBTC", msg.sender, 1000e8);
        vm.stopBroadcast();

        return NetworkConfig({
            wethUsdPriceFeed: address(wethUsdPriceFeed),
            wbtcUsdPriceFeed: address(wbtcUsdPriceFeed),
            weth: address(weth),
            wbtc: address(wbtc),
            deployerKey: DEFAULT_ANVIL_KEY
        });
    }
}
