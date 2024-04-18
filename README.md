# OVERVIEW

What does this actually do:

## Paracelsus.sol

createCampaign() launches a new Undine Contract.

The Undine launches an ERC20, and mints half of the supply to itself, and half of the supply to the ManaPool.
The launch is registered with Archivist.sol.

Paracelsus also has a tribute() which directs ETH into the Undine.
Contributions are also registered with Archivist.sol.

createCampaign() also triggers timestamp with a 24 Hour check period, for Chainlink Automation.

Chainlink Automation is set to InvokeLP() 24 Hours after launch -- Meaning, the ETH from the tribute() and the tokens minted to the Undine are combined into a Univ2LP which is held by the Undine.

## DEPLOYMENT



## DEPENDENCIES

Setting up a development environment for Paracelsus:

```bash
npm install -g npm
npm install --save-dev hardhat
npm install @openzeppelin/contracts
npm install @uniswap/v2-core
npm install dotenv
npm i @chainlink/contracts
npm install ethers
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
4) Campaigns can be run Once Per Week. -- Creates a Slow and Steady | Quality over Quantity Atmosphere.
