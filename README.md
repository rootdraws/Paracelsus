# OVERVIEW

Paracelsus is a decentralized Meme Token Launchpad following the Factory Pattern, where Undine serves as an ERC20 Child Contract for individual token campaigns.

Campaigns are structured as follows:

- **Paracelsus Invokes an Undine**: Which is an ERC20 token contract, each holding its own Liquidity Pool (LP).
- **ETH Crowdfunding Campaign**: ETH is contributed during a 24-hour crowdfunding campaign.
- **Supply Distribution**:
  - 50% of the token supply goes to an LP owned by the Undine contract.
  - 45% of the supply is available for claim by campaign contributors.
  - 5% of the supply is distributed to the ManaPool for LP incentives.

After the supply is distributed and the Uniswap V2 LP is formed, each Undine stakes their LP tokens at the ManaPool.

## MANAPOOL [LP Farming for Undine Contracts]

Each Undine deployed contributes 5% of its supply to the ManaPool upon launch.

- **Reward Distribution**: 1% of all tokens in the ManaPool are distributed weekly. This means the reward supply undergoes a vesting/limit curve decay and is bolstered with the supply from each new launch.
- **Staking**: Only Undine contracts can stake their LP tokens in the pool. LP rewards are weighted based on the amount of ETH raised by each campaign.

## ARCHIVIST

The Archivist tracks each campaign, including LP tokens, the total amount contributed, and individual contributors. This component serves as the historical ledger and data retrieval point for campaign analytics.

## AETHER

Aether serves as the inaugural token launched via Paracelsus, embodying the platform's principles and serving as a template for subsequent token campaigns.

## GAME MECHANICS

- **Consume() Function**: A command whereby an Undine can sell all of a specified token for ETH and then use that ETH to purchase more LP. This function can be called at any time and is token-gated, meaning it can only be executed by a holder of the specific token in question.

## DEPENDENCIES

To set up your development environment for Paracelsus, follow these steps:

```bash
npm install -g npm
npm install --save-dev hardhat
npm install @openzeppelin/contracts
npm install @uniswap/v2-core
```

## SETUP

```bash
npx hardhat
```

This markdown document provides a structured and detailed overview of the Paracelsus project, instructions for setting up the development environment, and insights into the unique game mechanics involved.
