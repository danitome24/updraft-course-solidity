//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();

        return uint256(price) * 1e10; // in WEI
    }

    function getConversion(uint256 _etherAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 price = getPrice(priceFeed);
        uint256 conversion = (price * _etherAmount) / 1e18;

        return uint256(conversion);
    }
}
