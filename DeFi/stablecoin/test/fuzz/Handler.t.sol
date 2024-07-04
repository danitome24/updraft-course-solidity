// SPDX-License-Identifier: MIT

// Handler is going to narrow down the way we call function

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract Handler is Test {
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dscEngine = _dscEngine;
        dsc = _dsc;

        address[] memory collatTokens = dscEngine.getCollateralTokens();
        weth = ERC20Mock(collatTokens[0]);
        wbtc = ERC20Mock(collatTokens[1]);
    }

    // Redeem collateral <- call this when there is collateral
    function depositCollateral(uint256 collateralSeed, uint256 randomAmountCollateral) public {
        ERC20Mock collateral = _getCollateralAddressFromSeed(collateralSeed);
        randomAmountCollateral = bound(randomAmountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, randomAmountCollateral);
        collateral.approve(address(dscEngine), randomAmountCollateral);
        dscEngine.depositCollateral(address(collateral), randomAmountCollateral);
        vm.stopPrank();
    }

    // Helper functions
    function _getCollateralAddressFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}
