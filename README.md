# OVERVIEW

Paracelsus is Decentralized a Meme Token Launchpad, with Contract-Owned LP, and Liquidity Incentive Curation.

## CAMPAIGN STRUCTURE

- **Paracelsus Invokes an Undine**: An ERC20 token contract, which custodies its own Univ2 liquidity pool (LP).
- **ETH Crowdfunding Campaign**: For 24 Hours after launch, Contributors can send ETH to the Undine to crowdfund LP. All ETH sent is added to LP, which is Owned by the Undine.
- **Each Undine mints a Max Supply of 1M TOKENS on Launch**:
  - 50% are used to form LP Owned by the Undine.
  - 45% are made available for claims to campaign contributors for 5 Days after the campaign.
  - 5% allocated to the ManaPool for LP incentives and ecosystem rewards.

## MANAPOOL [LP Farming for Undine Contracts]

Each Undine contributes 5% of its initial token supply to the ManaPool. Unclaimed tokens are also Absorbed into the ManaPool.

- **Weekly Epochs**: On a weekly basis, 1% of all tokens in the ManaPool are sold for ETH. This creates a decay curve, and a pool of ETH to use as Rewards for Undines. Each new launches bolsters the reward supply.
- **Dominance Hierarchy**: There is an ongoing score which is initially set by how much ETH was raised in the launch of each Undine. The more ETH is raised, the higher the Hierarchy, and the greater the Dominance Score. ETH is distributed to the Undines each Epoch based on this Dominance Score.

## VOTING ESCROW | STRIKE VOTES

The Voting Escrow system for Paracelsus allows any Undine Token to be Locked into a Salamander veNFT. These veNFTs have voting weights, which are based on the Dominance Score for the Undine of their underlying deposit.

However, instead of voting for your own Pool, you vote against pools that you don't think should get a reward for that epoch.

This system encourages community curation and responsible launches, as the consequence is a modification of your Dominance Hierarchy.

It's possible that a striken Undine would receive a smaller ETH reward during that Epoch, or none at all. If an Undine is repeatedly striken, then, it's Dominance Hierarchy is moved negative, and it will become more difficult for that Undine to regain favor with the broader ecosystem.

Undines with a negative Dominance Position receive no epoch rewards, and their tokens will be market sold by the ManaPool into Oblivion.

- **Vote Mechanism**: Salamander veNFT holders cast a strike for each Epoch.
- **Impact of Votes**: Strikes decrease an Undine's reward potential from the ManaPool, realigning ecosystem incentives towards community-approved projects.
- **Rebalancing Rewards**: The Strike Vote's outcome dynamically adjusts reward distribution, ensuring community-aligned projects receive a fairer share of the ManaPool rewards.

Voters are also given a portion of their Affiliated Undine's rewards, to incentivize curation and oparation of the protocol.

## ARCHIVIST

The Archivist component meticulously tracks each campaign's details, including LP tokens, total contributions, and participant contributions. It acts as the project's historical ledger and data retrieval point for analytics and governance.

## DEPENDENCIES AND SETUP

Setting up a development environment for Paracelsus:

```bash
npm install -g npm
npm install --save-dev hardhat
npm install @openzeppelin/contracts
npm install @uniswap/v2-core
```

```bash
npx hardhat
```

## TODO

Contracts are (un)Audited by Milady Ethereum Developer Shop | GPT.

Next areas of focus:

1) Votes can be cast once per week.
2) Votes are strikes, which curate the LP Rewards process.
3) Custom Art for each "tribe" | "underlying collateral"

Launch by 4/20.
