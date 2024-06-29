1. Relative Stability: Anchored or Pegged -> $1.00.
    1. Chainlink price feed to ensure pegged.
    2. Set a function to exchange ETH & BTC -> $$$
2. Stability Mechanism (Minting, Burning): Algorithmic (decentralized).
    1. People can only mint the stablecoin with enough collateral (coded)
3. Collateral: Exogenous (Crypto)
    1. wETH.
    2. wBTC

## Liquidate example

Threshold to 150%

- I put $100 ETH as collateral
- I borrow $50 DSC

if ETH value becomes $74 (less than threshold) you are undercollateralized! so 
any can pay back that $50 DSC and get all your collateral ($74).

You cannot leave your collateral be under that threshold never.

Course repository: https://github.com/Cyfrin/foundry-defi-stablecoin-cu
