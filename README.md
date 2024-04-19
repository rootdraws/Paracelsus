# HOW DOES IT ACTUALLY WORK?

## CONTRACTS

### PARACELSUS.SOL

Paracelsus is responsible for Launching Campaigns, and Invoking LP after the first 24 Hours.

createCampaign() launches a new Undine Contract.

* 50% Supply Minted to Undine for LP -- [Performed by Chainlink Automation 24 Hours after each createCampaign()]
* 45% Supply Minted for Initial Claim
* 5% Supply Minted to ManaPool for LP Rewards
* Launch is registered with Archivist.sol.

### UNIDNE.SOL

Undines are ERC20 contracts, which custody their own UniV2 LP.

* Undines mint 100% of their supply in the constructor, and then Accept ETH as tribute().
* 100% of the ETH accepted as tribute is transformed into Contract Owned LP, via Chainlink Automation.
* Each Week, the Undine receive ETH from the ManaPool according to their Undine Rank -- [compoundLP() is performed via Chainlink Automation on a weekly basis.]

### TRIBUTARY.SOL

tribute() gives ETH to the Undine | Open for 24 Hours from first tribute().

* .01 ETH Minimum
* Contributions are registered with Archivist.sol
* CLaims are available from ManaPool -- [Calculations Performed by Chainlink Automation 24 Hours after first tribute() of each campaign.]

### MANAPOOL.SOL

The ManaPool is inspired by [The Moonbased Rovers](https://moon.based.money/), as well as [Chainlink BUILD](https://blog.chain.link/chainlink-economics-2-0-one-year-update/), and Aerodrome's Bribe Model.

* The ManaPool accepts 5% of Token Supply from every Undine Launched.
* Chainlink Automation is used to Market Sell 1% of those tokens for ETH on a weekly cycle.
* The ManaPool captures ETH from Undine Markets, and returns that ETH to compound Undine Owned LP, according to their Rank.
* LINK tokens are also purchased to perpetuate Automation Upkeeps.

### ARCHIVIST.SOL

The Archivist serves two main purposes:

1) The Archivist serves as a Registry for each Undine Campaign Launched.
2) The Archivist Processes Undine Dominance Ranking each Week -- [performed via Chainlink Automation.]

#### UNDINE DOMINANCE HIERARCHY

Dominance is a performance metric based on how much ETH was raised in the launch of each Undine, compared to the sum of all ETH raised by all Undines.

* amountRaised / totalAmountRaised = dominancePercentage

These variables are dynamic, since amountRaised increases with each dispersal from the ManaPool, and the totalAmountRaised increases with each campaign.

#### REWARD DECAY

There is also a Reward Decay, where the bottom 20% in the Dominance Hierarchy receive a strike against their Ranking during that epoch.

Rankings are fluid, and if an Undine's Ranking goes to 0, then it can no longer claim any value from the ManaPool.

## DEPLOYMENT

### SEPOLIA MAINNET

* UniswapV2Router02 [0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008](https://sepolia.etherscan.io/address/0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008#code)
* UniswapV2Factory [0x7E0987E5b3a30e3f2828572Bb659A548460a3003](https://sepolia.etherscan.io/address/0x7E0987E5b3a30e3f2828572Bb659A548460a3003#code)
  * [Univ2 Docs](https://docs.uniswap.org/contracts/v2/overview)
* Chainlink Automation Registry [0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad](https://sepolia.etherscan.io/address/0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad#code)
* Chainlink Automation Registrar [0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976](https://sepolia.etherscan.io/address/0xb0e49c5d0d05cbc241d68c05bc5ba1d1b7b72976#code)
  * [Chainlink Automation Docs](https://automation.chain.link/)

### BASE

* UniswapV2Router02 [0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24](https://basescan.org/address/0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24)
* UniswapV2Factory [0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6](https://basescan.org/address/0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6)
* [Univ2 Docs](https://docs.uniswap.org/contracts/v2/overview)
* Chainlink Automation Registry [0xE226D5aCae908252CcA3F6CEFa577527650a9e1e](https://basescan.org/address/0xE226D5aCae908252CcA3F6CEFa577527650a9e1e)
* Chainlink Automation Registrar [0xD8983a340A96b9C2Bb6855E46847aE134Db71fB1](https://basescan.org/address/0xD8983a340A96b9C2Bb6855E46847aE134Db71fB1#code)
  * [Chainlink Automation Docs](https://automation.chain.link/)

### DEPENDENCIES

Setting up a development environment for Paracelsus:

```bash
npm install -g npm
npm install --save-dev hardhat
npm install @openzeppelin/contracts
npm install dotenv
npm install ethers
npm install @uniswap/v2-core
npm i @chainlink/contracts
```

```bash
npx hardhat
```

Contracts are (un)Audited by Milady Ethereum Developer Shop | GPT.

### TODO

1) Campaigns can be run Once Per Week. -- Creates a Slow and Steady | Quality over Quantity Atmosphere.
