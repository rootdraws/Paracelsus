
# OVERVIEW

Paracelsus is a Meme Token Launchpad [Factory Pattern] | Undine is an ERC20 [Child Contract]

Campaigns are structured as follows:

* Paracelsus Invokes an Undine -- Which is an ERC20, which holds its own LP.
* ETH is contributed in a 24 Hour Crowdfunding campaign.
* 50% of Supply goes to Undine Owned LP.
* 45% of is available for Claim by Campaign Contributors.
* 5% of Supply is distributed to the ManaPool for LP Incentives.

Once supply is distributed, and the Univ2 LP is formed, each Undine stakes their LP at the ManaPool.

.:.

## MANAPOOL [LP Farming for Undine Contracts]

Each Undine deployed contributes 5% of its supply to the ManaPool at launch.

1% of all tokens in the ManaPool are distributed weekly, which means reward supply has a vesting | limit curve decay, and is bolstered with supply from each launch.

Only Undine can stake their LP Tokens to the pool, and LP Rewards are weighted based the amount of ETH Raised by each Campaign.

.:.

## ARCHIVIST

The Archivist tracks each campaign, the LP tokens, the total amount contributed, and the individual contributors.

.:.

## AETHER

.:.

## GAME MECHANICS

Consume() is a command where the Undine will sell all of a specified token for ETH, and compound that ETH into more LP. The Function can be called at any time, and is a token-gated function which can only be called by a holder from that token.

## DEPENDENCIES

'npm install -g npm'
'npm i hardhat'
'npm i @openzeppelin/contracts'
'npm i @uniswap/v2-core'
