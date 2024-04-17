// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Archivist.sol";
import "./ManaPool.sol";
import "./Salamander.sol";
import "./EpochManager.sol";
import "./Undine.sol";

contract Paracelsus {
    address public uniV2Router;
    Archivist public archivist;
    ManaPool public manaPool;
    Salamander public salamander;
    EpochManager public epochManager;

// EVENTS | Consider Twitter | Frontend | Discord | Warpcast Frame Announcement Integrations
    event UndineDeployed(address indexed undineAddress, string tokenName, string tokenSymbol); // Signals open to 24 HR Contribution Period.
    event LPPairInvoked(address indexed undineAddress, address lpTokenAddress); // LP Ready for Trade
    
    event TributeMade(address indexed undineAddress, address indexed contributor, uint256 amount);  // Frontend | Discord
    event MembershipClaimed(address indexed undineAddress, uint256 claimAmount); // Frontend | Discord


// CONSTRUCTOR
    constructor(
        address _uniV2Router,
        address _archivist,
        address _manaPool,
        address _salamander,
        address _epochManager
    ) {
        uniV2Router = _uniV2Router;
        archivist = Archivist(_archivist);  // Cast address to Archivist contract type
        manaPool = ManaPool(_manaPool);    // Cast address to ManaPool contract type
        salamander = Salamander(_salamander); // Cast address to Salamander contract type
        epochManager = EpochManager(_epochManager); // Cast address to EpochManager contract type

        // Setting up the address books using the properly cast types
        archivist.setArchivistAddressBook(
            uniV2Router,
            address(this),
            address(manaPool),
            address(salamander),
            address(epochManager)
        );

        manaPool.setManaPoolAddressBook(
            uniV2Router,
            address(this),
            address(archivist),
            address(salamander),
            address(epochManager)
        );

        salamander.setSalamanderAddressBook(
            uniV2Router,
            address(this),
            address(archivist),
            address(manaPool),
            address(epochManager)
        );

        epochManager.setEpochManagerAddressBook(
            address(this),
            address(archivist),
            address(manaPool),
            address(salamander)
        );
    }


// LAUNCH | createCampaign() requires sending .01 ETH to the ManaPool, and then launches an Undine Contract.

/*

MODIFICATIONS: 

1) There are some hard-coded variables in here, which could be variables which are set by a DAO. This would also imply that there was a general DAO which controlled those variables. This could be done with a Moloch Structure, and then giving permissions to that Baal contract to execute those functions, and then creating transactions, which would initiate a vote.
2) It's also possible to whitelist which campaigns could launch here, using a DAO structure. 
3) It's also possible to have a limit on how many campaigns can be launched per epoch.
4) Structure so that one campaign may be booked per epoch.

FRONTEND: 

1) Will need a type of form, that expresses the ETH to be deposited, and enters the tokenName and tokenSymbol.
2) Will need to trigger the population of an "ACTIVE CAMPAIGN" section, with timer.

EVENT: 

Consider a discordbot | twitterbot which announces when a new campaign is live, as an invite to snipers.

*/
    
    function createCampaign(
        string memory tokenName,   // Name of Token Launched
        string memory tokenSymbol  // Symbol of Token Launched
    ) public payable {
        require(msg.value == 0.01 ether, "Must deposit 0.01 ETH to ManaPool to invoke an Undine.");
        
        // Send ETH to ManaPool for Launch Fee
        manaPool.deposit{value: msg.value}();
        
        // New Undine Deployed
        Undine newUndine = new Undine(
            tokenName,
            tokenSymbol,
            uniV2Router,
            address(archivist),
            address(manaPool),
            address(this)
        );

        // Transfer ownership of the new Undine to Paracelsus
        address newUndineAddress = address(newUndine);
        newUndine.transferOwnership(address(this));

        // Initial placeholders for campaign settings
        address lpTokenAddress = address(0); // Placeholder for LP token address, to be updated after LP creation
        uint256 amountRaised = 0;            // Initial amount raised, will be updated as contributions are received

        // Campaign Duration setup
        uint256 startTime = block.timestamp;                 // Campaign starts immediately
        uint256 duration = 1 days;                           // Campaign concludes in 24 hours
        uint256 endTime = startTime + duration;
        uint256 startClaim = endTime;                        // Claim starts immediately after campaign ends
        uint256 claimDuration = 5 days;                      // Claim window lasts for 5 days
        uint256 endClaim = startClaim + claimDuration; 

        // Register the new campaign with Archivist
        archivist.registerCampaign(newUndineAddress, tokenName, tokenSymbol, lpTokenAddress, amountRaised, startTime, endTime, startClaim, endClaim);

        // Event
        emit UndineDeployed(newUndineAddress, tokenName, tokenSymbol);
    }


/*

MODIFICATIONS: 
1) Min and Max contributions could be variables which are set by a Moloch DAO.
2) Structure so that Tributes happen on a specific DAY of each Epoch.

FRONTEND: 
1) 24 HR countdown timer
2) Pick the campaign you like out of a list, and then enter Amount, with info of .01 MIN and 10 MAX. 

A list ought to alleviate the need to enter undineAddress for each tx, because each list item would be for a unique undineAddress. 
Frontend populates a new active Listing each time UndineDeployed event is signaled.

*/

// TRIBUTE | Contribute ETH to Undine
    function tribute(address undineAddress, uint256 amount) public payable {
        // Check if the amount is within the allowed range
        require(amount >= 0.01 ether, "Minimum deposit is 0.01 ETH.");
        require(amount <= 10 ether, "Maximum deposit is 10 ETH.");
        require(msg.value == amount, "Sent ETH does not match the specified amount.");
        require(archivist.isCampaignActive(undineAddress), "The campaign is not active or has concluded.");

        // Assuming Undine has a deposit function to explicitly receive and track ETH
        Undine undineContract = Undine(undineAddress);

        // Send ETH to Undine
        undineContract.deposit{value: msg.value}();

        // Archivist is updated on Contribution amount for [Individual | Campaign | Total]
        archivist.addContribution(undineAddress, msg.sender, amount);

        // Event
        emit TributeMade(undineAddress, msg.sender, amount);
    }

/*

FRONTEND:

Once a campaign moves out of its completion period, you will need a "Pending Processing" List, with actions which need to be completed.

invokeLP() is an action that one of the contributors, or the deployer will need to call in order for the Undine to progress.

Event can signal Discord announcement of "New LP Pair available for Trade: 0xADDY"

LPPairInvoked also signals a list transition to "OPEN CLAIM PERIOD"

*/
    
// LIQUIDITY | Create Univ2 LP to be Held by Undine || Call invokeLP() once per Undine.
   function invokeLP(address undineAddress) external {
        require(archivist.isCampaignConcluded(undineAddress), "Campaign is still active.");
        require(archivist.isLPInvoked(undineAddress), "Campaign already has Invoked LP.");

        // Forms LP from Entire Balance of ETH and ERC20 held by Undine [50% of Supply]
        Undine(undineAddress).invokeLiquidityPair();

        // Pull LP Address from Undine via UniV2 Factory
        address lpTokenAddress = Undine(undineAddress).archiveLP();

        // Update Archivist with the LP Address for Campaign[]
        archivist.archiveLPAddress(undineAddress, lpTokenAddress);

         // Event
        emit LPPairInvoked(undineAddress, lpTokenAddress);
    }

// CLAIM | Claim tokens held by ManaPool

/*

MODIFICATIONS:
1) Claims are Active during fixed DAYS of each epoch.


NOTES: 
1) Tokens Forfeit to ManaPool after Claim Period.
2) Call claimMembership() once per Campaign | per Member.

FRONTEND:

CLAIM PERIOD frontend section lists Undines with open claim periods, and has a claimMembership() button, and a timer.

*/
  
    function claimMembership(address undineAddress) public {
        // Check if the claim window is active
        require(archivist.isClaimWindowActive(undineAddress), "Claim window is not active.");

        // Calculate claim amount using Archivist
        archivist.calculateClaimAmount(undineAddress, msg.sender);

        // Retrieve the claim amount using the new getter function
        uint256 claimAmount = archivist.getClaimAmount(undineAddress, msg.sender);

        // Ensure the claim amount is greater than 0
        require(claimAmount > 0, "Claim amount must be greater than 0.");

        // Transfer the claimed tokens from ManaPool to the contributor
        manaPool.claimTokens(msg.sender, undineAddress, claimAmount);

        // Reset the claim amount in Archivist
        archivist.resetClaimAmount(undineAddress, msg.sender);

        // Emit event
        emit MembershipClaimed(undineAddress, claimAmount);
    }

/*

MODIFICATIONS:
transmutation() | distillation() == ManaPool conversion of Tokens into ETH takes place on specific DAY of each Epoch.

FRONTEND:

CLAIM PERIOD frontend section lists Undines with open claim periods, and has a claimMembership() button, and a timer.

*/

// LP REWARDS | Function can be called once per Epoch | Epoch is defined as one week.

   function triggerTransmutePool() external {
        // First check if it's allowed to trigger a new epoch
        require(epochManager.isTransmuteAllowed(), "Cooldown period has not passed.");

        // Sells 1% of ManaPool into ETH to be Distributed to Undines
        manaPool.transmutePool();

        // Calculate the Vote Impact Per Salamander
        // Calculates the Distribution Amounts per Undine || To Be Edited to Include Voting Escrow
        manaPool.updateRewardsBasedOnBalance();

        // Update the epoch in the EpochManager
        epochManager.updateEpoch();
    }

// veNFT

    // LOCK Tokens from any UNDINE for 1 Year, and gain Curation Rights
    function lockVeNFT(ERC20 token, uint256 amount) external {
        salamander.lockTokens(token, amount);
    }

    // UNLOCK Tokens and Burn your veNFT after 1 Year
    function unlockVeNFT(uint256 tokenId) external {
        salamander.unlockTokens(tokenId);
    }

    // TODO: VOTE FUNCTION 
}
