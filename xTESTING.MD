# TEST()

## SEPOLIA TEST ACCOUNTS

Account 1 - Address: 0x63Bee49E5Bb48CE166E0dc5C7Ab878e1dc0b6D30
Account 2 - Address: 0x4f4521B04E33Ef7D8724CE01E3A0635a9a22D171
Account 3 - Address: 0x596E61651FC54b377Fc543f237CB99F42C471319
Account 4 - Address: 0xC03Fa61d7666B62EB153c762BcED89ec91Be904F
Account 5 - Address: 0x7B838aa340bcEcaa4a81724E05339f26bE334b84
Account 6 - Address: 0x53Dfa25F9668809c12924bd538EaE496a4928401
Account 7 - Address: 0xDB987D7521A0959f6AAEa1f5ECcB70a636cAba79
Account 8 - Address: 0x91a96dc80d5d8AcC4f427d7348b3757ede5234E2
Account 9 - Address: 0x64F1e26891dF924b7d8E52a3C7BE2bcFa38e935a
Account 10 - Address: 0x88b42368B939C991Ef1C151e8510a8aCC90ED62b

## PREP

[AUTOMATION REGISTERED](https://automation.chain.link/sepolia)

/*

Another issue here, is that the "deployer wallet" needs to be the one who funds and increases funding for these chainlink automation accounts.

This means that there will need to be a Multisig | Moloch DAO that receives LINK tokens via the distillation process, and then the Automation Registry needs to be created with that deployer acct.

This would probably be a good time to start thinking about how to use Gnosis Defender in order to deploy contracts, and how you would set those up with a Gnosis Safe Module.

*/

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

## ARCHIVIST

/*

There should be more clear ways to Query all of the information avaialble in the Archivist, even a singular function that shares multiple variables. 
Something like this would be useful for testing, and would test multiple read functions at the same time.

*/

### Constructor Archivist

- **setArchivistAddressBook(address _uniV2Router, address _paracelsus, address _manaPool)**: Sets the addresses for related contracts (router, paracelsus, and mana pool).

### Campaign Management

- **registerCampaign(address _undineAddress, string memory _tokenName, string memory _tokenSymbol, address _lpTokenAddress, uint256 _amountRaised, bool _campaignOpen)**: Registers a new campaign.
- **archiveLPAddress(address undineAddress, address lpTokenAddress)**: Updates the LP token address for a specified campaign.
- **addContribution(address undineAddress, address contributor, uint256 amount)**: Adds a contribution to a campaign.
- **closeCampaign(address undineAddress)**: Closes a specified campaign.
- **closeCampaign()**: Closes the currently active campaign, resetting the campaignInSession flag.

### Query Functions

- **getLatestOpenCampaign()**: Returns the address of the most recently opened campaign.
- **isCampaignOpen(address undineAddress)**: Checks if a specified campaign is open.
- **isCampaignInSession()**: Checks if any campaign is currently in session.
- **getUnprocessedCampaign()**: Finds and returns the address of a campaign that is closed but not yet processed for claims.
- **getLatestOpenClaims()**: Returns the address of the latest campaign that has open claims.
- **getAllUndineAddresses()**: Returns a list of all Undine addresses from all campaigns.

### Contribution and Claims

- **getClaimAmount(address undineAddress, address claimant)**: Retrieves the claim amount for a specific contributor of a campaign.
- **resetClaimAmount(address undineAddress, address claimant)**: Resets the claim amount for a specific contributor to zero.
- **calculateClaimsForCampaign(address undineAddress)**: Calculates claim amounts for all contributors of a specified campaign.
- **closeClaims(address undineAddress)**: Closes the claims for a specified campaign.

### Dominance and Reward Calculation

- **calculateDominanceAndWeights()**: Calculates the dominance percentage for each campaign based on the amount raised.
- **calculateRewards(uint256 manaPoolBalance)**: Distributes rewards to campaigns based on their dominance.
- **applyDecay()**: Applies a decay to the amount raised in each campaign to simulate economic factors or to gradually reduce values over time.

### Automation and Chainlink Integration

- **setDistillationFlag(bool _flag)**: Sets a flag indicating whether distillation is needed, based on external conditions or a scheduled task.
- **resetDistillationFlag()**: Resets the distillation flag to false.
- **checkUpkeep(bytes calldata)**: Checks if upkeep is needed, specifically checking the distillation flag.
- **performUpkeep(bytes calldata)**: Performs upkeep by calling the distillation function in the ManaPool, resets the distillation flag, and closes the current campaign.

### Events

- **DominanceCalculated(address indexed undineAddress, uint256 dominancePercentage)**: Emitted when dominance is calculated.
- **CampaignRegistered(address indexed undineAddress, string tokenName, string tokenSymbol)**: Emitted when a new campaign is registered.
- **LPTokenAddressUpdated(address indexed undineAddress, address lpTokenAddress)**: Emitted when an LP token address is updated.
- **RewardsDistributed(uint256 totalDistributed)**: Emitted when rewards are distributed.
- **CampaignStatusUpdated(address indexed undineAddress, bool isOpen)**: Emitted when a campaign status is updated.
- **ClaimsCalculated(address indexed undineAddress)**: Emitted when claims are calculated for a campaign.
- **CampaignClaimsUpdated(address indexed undineAddress, bool campaignOpen, bool claimsOpen)**: Emitted when campaign claims are updated.

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

## ManaPool

### Constructor ManaPool

- **setManaPoolAddressBook(address _uniV2Router, address _paracelsus, address _archivist)**: Sets necessary addresses for interacting with other contracts.

### ETH Management

- **deposit()**: Allows the contract to receive ETH deposits directly to its address.

### Claims Management

- **claimTokens()**: Allows users to claim their tokens based on the Archivist’s records. This function checks for valid claims and ensures claims can only be made within the specified time frame. It also interacts with the `Archivist` to reset claim amounts.

### Token and ETH Balances

- **currentBalance()**: Returns the current ETH balance of the `ManaPool`.

### Distillation Process

- **distillation()**: Handles the selling of a specified percentage of each ERC-20 token held by the contract for ETH. This function is intended to be called periodically through automation and uses the Uniswap V2 Router to perform the market sell.

### Automation Functions

- **checkUpkeep(bytes calldata)**: Checks if the conditions for performing upkeep are met, specifically if the time has passed for claims to close.
- **performUpkeep(bytes calldata)**: Performs the necessary upkeep actions. This includes closing claims, calculating rewards, and setting the distillation flag.

### Event Logging

- **ClaimsClosed(address indexed undineAddress)**: Emitted when claims for a specific campaign are closed.
- **TokensClaimed(address indexed undineAddress, uint256 amount)**: Emitted when tokens are successfully claimed by a user.

This contract serves as an essential part of a decentralized ecosystem, managing the distribution and conversion of tokens to ensure liquidity and reward mechanisms function as intended.

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

## Paracelsus

### Constructor Paracelsus

- **constructor(address _uniV2Router, address _archivist, address _manaPool, address _tributary)**: Initializes the contract and sets up necessary addresses for other components like the router, archivist, mana pool, and tributary.

### Campaign Management Paracelsus

- **createCampaign(string memory tokenName, string memory tokenSymbol)**: Launches a new `Undine` token campaign, registers it with the `Archivist`, and initializes campaign data.

/*

Create an endTime variable here for launches, and an endClaim variable for end of claim. Then, modify the Archivist to receive these values, and create functions in the archivist to call those values.

This way we could tell in advance when the time is up -- and if the variables exist, then, we could probably call them from the frontend.

*/

### Automation and Upkeep

- **checkUpkeep(bytes calldata)**: Checks if the conditions for performing upkeep are met, specifically whether it has been 24 hours since the campaign creation without liquidity pairing.
- **performUpkeep(bytes calldata performData)**: Performs the necessary upkeep actions, which include invoking liquidity pairing, updating archival records, and closing the campaign.

### Events Paracelsus

- **UndineDeployed(address indexed undineAddress, string tokenName, string tokenSymbol)**: Emitted when a new `Undine` campaign is successfully launched.

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

## TRIBUTARY

### Configuration and Address Setting

- **setTributaryAddressBook(address _archivist, address _manaPool)**: Configures the contract with external addresses for the `Archivist` and `ManaPool`. This ensures that `Tributary` can interact with other parts of the system.

### Contribution Handling

- **tribute(uint256 amount)**: Allows contributors to send ETH to the campaign within a 24-hour window after its launch. It records contributions in the `Archivist` and triggers related events.

### Automation and Upkeep | TRIBUTARY

- **checkUpkeep(bytes calldata)**: Checks if there is an unprocessed campaign that has been closed but not yet processed for claims. This function is part of the automation interface to determine if the contract needs to perform upkeep.
- **performUpkeep(bytes calldata performData)**: Processes claims for a campaign once it is determined that upkeep is needed. This function calculates the claim amounts for each contributor based on the data in the `Archivist`.

### Events Tributary

- **TributeMade(address indexed undineAddress, address indexed contributor, uint256 amount)**: Emitted when a contribution is made to a campaign, providing transparency and traceability of contributions.

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

## UNDINE

/*

 An Issue with the Undines, is that the factory contract which creates new campaigns requires the Undines to register their Automation after deployment.
 This is not possible, because we need to do this without maintenance.

We can test the logic of these functions, but we would need to export them to another area.

*/

### Constructor | UNDINE

- **constructor(string memory name, string memory symbol, address _uniV2Router, address _paracelsus, address _archivist, address _manaPool)**: Initializes the contract with token details, Uniswap router, and addresses for related contracts such as Paracelsus, Archivist, and ManaPool. It also mints the initial supply of tokens.

### Token Management

- **deposit() external payable**: Allows the contract to receive ETH directly from transactions.

### Liquidity Operations

- **invokeLiquidityPair() external**: Adds liquidity to a Uniswap pool using all ETH and ERC20 tokens held by the contract, setting up an LP token and updating relevant state variables.

### Automation and Upkeep | UNDINE

- **checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData)**: Checks if there is a need to perform upkeep, specifically looking if the contract balance is above zero and an LP token address is set.
- **performUpkeep(bytes calldata) external override**: Performs the actual upkeep which includes swapping ETH for tokens and adding liquidity to Uniswap, effectively reinvesting into the liquidity pool.

### Events | UNDINE

- **LPPairInvoked(address indexed undineAddress, address lpTokenAddress)**: Emitted after liquidity is added to a Uniswap pool, indicating the operation was successful and providing the new LP token address.
- **LPCompounded(address indexed undineAddress, address lpTokenAddress)**: Emitted after liquidity is compounded within the Uniswap pool, indicating that the reinvestment was successful.

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
