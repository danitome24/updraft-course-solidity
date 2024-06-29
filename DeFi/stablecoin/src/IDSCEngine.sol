// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDSCEngine {
    function depositCollateralAndMintDSC() external;

    /**
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) external;

    function redeemCollateralForDSC() external;

    function redeemCollateral() external;

    /**
     * @param amountDscToMint The amount of DSC to mint
     * @notice They must have more collateral value than minimum threshold
     */
    function mintDSC(uint256 amountDscToMint) external;

    function burnDSC() external;

    function liquidate() external;

    function getHealthFactor() external view;
}
