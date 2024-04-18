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

// EVENTS
    event UndineDeployed(address indexed undineAddress, string tokenName, string tokenSymbol); 
    event LPPairInvoked(address indexed undineAddress, address lpTokenAddress);
    
    event TributeMade(address indexed undineAddress, address indexed contributor, uint256 amount);
    event MembershipClaimed(address indexed undineAddress, uint256 claimAmount);


// CONSTRUCTOR
    constructor(
        address _uniV2Router,
        address _archivist,
        address _manaPool,
        address _salamander,
        address _epochManager
    ) {
        uniV2Router = _uniV2Router;
        archivist = Archivist(_archivist);
        manaPool = ManaPool(_manaPool);
        salamander = Salamander(_salamander);
        epochManager = EpochManager(_epochManager);

    // SET ADDRESSES    
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


// LAUNCH
    function createCampaign(
        string memory tokenName,
        string memory tokenSymbol
    ) public payable {
        require(msg.value == 0.001 ether, "Must deposit 0.001 ETH to ManaPool to invoke an Undine.");
        
        // LAUNCH FEE
        manaPool.deposit{value: msg.value}();
        
        // New Undine Deployed
        Undine newUndine = new Undine(
            tokenName,
            tokenSymbol,
            uniV2Router,
            address(this),
            address(archivist),
            address(manaPool),
            address(salamander),
            address(epochManager)
        );

        address newUndineAddress = address(newUndine);

        // Placeholders for Campaign Array
        address lpTokenAddress = address(0);
        uint256 amountRaised = 0;

// EXPORT TO EpochManager
        uint256 startTime = block.timestamp;                 // Campaign starts immediately
        uint256 duration = 1 days;                           // Campaign concludes in 24 hours
        uint256 endTime = startTime + duration;
        uint256 startClaim = endTime;                        // Claim starts immediately after campaign ends
        uint256 claimDuration = 5 days;                      // Claim window lasts for 5 days
        uint256 endClaim = startClaim + claimDuration; 

// MODIFY DUE TO Epoch Manager | Register the new campaign with Archivist
        archivist.registerCampaign(newUndineAddress, tokenName, tokenSymbol, lpTokenAddress, amountRaised, startTime, endTime, startClaim, endClaim);

        // Event
        emit UndineDeployed(newUndineAddress, tokenName, tokenSymbol);
    }

// TRIBUTE | Contribute ETH to Undine
    function tribute(address undineAddress, uint256 amount) public payable {
        // Check if the amount is within the allowed range
        require(amount >= 0.01 ether, "Minimum deposit is 0.01 ETH.");
        require(amount <= 10 ether, "Maximum deposit is 10 ETH.");
        require(msg.value == amount, "Sent ETH does not match the specified amount.");
// EPOCH MANAGER | require(epochManager.isCampaignActive(undineAddress), "The campaign is not active or has concluded.");

        // Assuming Undine has a deposit function to explicitly receive and track ETH
        Undine undineContract = Undine(undineAddress);
        undineContract.deposit{value: msg.value}();

        // Archivist is updated on Contribution amount for [Individual | Campaign | Total]
        archivist.addContribution(undineAddress, msg.sender, amount);

        // Event
        emit TributeMade(undineAddress, msg.sender, amount);
    }
    
// LIQUIDITY | Create Univ2 LP to be Held by Undine || Call invokeLP() once per Undine.
   function invokeLP(address undineAddress) external {
// EPOCH MANAGER require(archivist.isCampaignConcluded(undineAddress), "Campaign is still active.");
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
    function claimMembership(address undineAddress) public {
// EPOCH MANAGER | Check if the claim window is active
        //require(archivist.isClaimWindowActive(undineAddress), "Claim window is not active.");

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

// LP REWARDS | Function can be called once per Epoch | Epoch is defined as one week.
   function transmutation() external {
// EPOCH MANAGER | Create Requirements and Automate  ManaPool conversion of Tokens into ETH takes place on specific DAY of each Epoch.
        require(epochManager.isTransmuteAllowed(), "Cooldown period has not passed.");

        // Sells 1% of ManaPool into ETH to be Distributed to Undines
        manaPool.transmutePool();

        // Calculate the Vote Impact Per Salamander
        // Calculates the Distribution Amounts per Undine || To Be Edited to Include Voting Escrow
        manaPool.updateRewardsBasedOnBalance();

        // Update the epoch in the EpochManager
        epochManager.updateEpoch();
    }

// veNFT | Integrate with Manifold

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
