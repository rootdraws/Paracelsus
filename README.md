# HOW DOES IT ACTUALLY WORK?

## CONTRACTS

### PARACELSUS.SOL

Paracelsus is responsible for Launching Campaigns, and Invoking LP after the first 24 Hours.

createCampaign() launches a new Undine Contract.

* 50% Supply Minted to Undine for LP
* 45% Supply Minted for Claim
* 5% Supply Minted to ManaPool
* Launch is registered with Archivist.sol.

### TRIBUTARY.SOL

tributeTierI() gives ETH to the Undine | Artist.

* .01 ETH Minimum
* Contributions are registered with Archivist.sol

tributeTierII() gives ETH to the Undine | Artist.

* .1 ETH NFT
* ETH contributed to Undine goes to LP / Artist
* Contributions are registered with Archivist.sol

tributeTierIII() gives ETH to the Undine | Artist.

* .2 ETH Custom Commission
* ETH contributed to Undine goes to LP / Artist
* Contributions are registered with Archivist.sol

Chainlink Automation uses InvokeLP() 24 Hours after createCampaign().

### SEPOLIA

#### UNISWAP

* UniswapV2Router02 [0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008](https://sepolia.etherscan.io/address/0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008#code)
* UniswapV2Factory [0x7E0987E5b3a30e3f2828572Bb659A548460a3003](https://sepolia.etherscan.io/address/0x7E0987E5b3a30e3f2828572Bb659A548460a3003#code)
* [Univ2 Docs](https://docs.uniswap.org/contracts/v2/overview)

#### AUTOMATION

* Chainlink Automation Registry [0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad](https://sepolia.etherscan.io/address/0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad#code)
* Chainlink Automation Registrar [0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976](https://sepolia.etherscan.io/address/0xb0e49c5d0d05cbc241d68c05bc5ba1d1b7b72976#code)
* [Chainlink Automation Docs](https://automation.chain.link/)

#### MANIFOLD

* [Manifold Docs](https://docs.manifold.xyz/v/manifold-for-developers/smart-contracts/manifold-creator)
* [Manifold Merkel | Snapshot Tool](https://docs.manifold.xyz/v/manifold-for-developers/tools-and-apis/merkle-tree-tool)

### DEPLOYMENT

### DEPENDENCIES

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

### TODO

Contracts are (un)Audited by Milady Ethereum Developer Shop | GPT.

Next areas of focus:

1) Votes can be cast once per week.
2) Votes are strikes, which curate the LP Rewards process.
3) Custom Art for each "tribe" | "underlying collateral"
4) Campaigns can be run Once Per Week. -- Creates a Slow and Steady | Quality over Quantity Atmosphere.
