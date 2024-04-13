// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// Archivist stores and provides all data for Paracelsus and Undine Contracts.
// Archivist provides data for the UI | UX, to allow people to pick campaigns, join them, and execute transactions.

contract Archivist is Ownable {
    
    address public paracelsus;
    address public manaPool;
    address public salamander;     
    uint256 public totalValueRaised = 0;

// CAMPAIGN[]
    struct Campaign {
        address undineAddress;
        string tokenName;
        string tokenSymbol;
        address lpTokenAddress;
        uint256 amountRaised;
        uint256 startTime;
        uint256 endTime;
        uint256 startClaim;
        uint256 endClaim;
    }

    Campaign[] public campaigns;
    Dominance[] public dominanceRankings;
    mapping(address => uint256) public campaignIndex;

// CONTRIBUTIONS

    // Nested mapping: Campaign Address => (Contributor Address => Contribution Info)
    mapping(address => mapping(address => Contribution)) public contributions;

    struct Contribution {
        uint256 tributeAmount;
        uint256 claimAmount; // Initially set to 0 | Existential variable for Dominance Score Ranking
    }

// DOMINANCE HIERARCHY

 struct Dominance {
        address undineAddress;
        uint256 dominancePercentage;
        uint256 manaPoolReward;
    }

// EVENT
    event DominanceCalculated(address indexed undineAddress, uint256 dominancePercentage);
    event CampaignRegistered(address indexed undineAddress, string tokenName, string tokenSymbol);

// CONSTRUCTOR | Establishes Paracelsus as Owner
    
    constructor(address _paracelsus) {
        require(_paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        paracelsus = _paracelsus;

        // Immediately transfer ownership to the Paracelsus contract
        transferOwnership(paracelsus);
    }

// ADDRESSES
    // ManaPool
    function setManaPool(address _manaPool) external onlyParacelsus {
        require(_manaPool != address(0), "ManaPool address cannot be the zero address.");
        manaPool = _manaPool;
    }

    // Salamander
    function setSalamander(address _salamander) external onlyParacelsus {
        require(_salamander != address(0), "ManaPool address cannot be the zero address.");
        salamander = _salamander;
    }

// SECURITY
    modifier onlyParacelsus() {
        require(msg.sender == paracelsus, "Caller is not Paracelsus");
        _;
    }

    modifier onlyManaPool() {
        require(msg.sender == manaPool, "Caller is not ManaPool");
        _;
    }

// REGISTRATION | Registers New Instances of Undine | New Campaigns || Owned by Paracelsus
        function registerCampaign(
        address _undineAddress,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _lpTokenAddress,
        uint256 _amountRaised,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startClaim,
        uint256 _endClaim
    ) external onlyParacelsus { 
        Campaign memory newCampaign = Campaign({
            undineAddress: _undineAddress,
            tokenName: _tokenName,
            tokenSymbol: _tokenSymbol,
            lpTokenAddress: _lpTokenAddress,
            amountRaised: _amountRaised,
            startTime: _startTime,
            endTime: _endTime,
            startClaim: _startClaim,
            endClaim: _endClaim
        });

        campaigns.push(newCampaign);
        campaignIndex[_undineAddress] = campaigns.length - 1;

        // Event
        emit CampaignRegistered(_undineAddress, _tokenName, _tokenSymbol);
    }


// TRIBUTE | Campaign Active Check
    function isCampaignActive(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return block.timestamp >= campaign.startTime && block.timestamp <= campaign.endTime;
    }

// TRIBUTE | TVL Incrementation | Campaign Incrementation | Individual Contribution Record
    function addContribution(address undineAddress, address contributor, uint256 amount) external onlyParacelsus {
        // Assuming you have validated the campaign's active status in the calling function
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        
        // Dynamic Campaign Level Increment
        campaign.amountRaised += amount;

        // Dynamic Individual Contribution Increment
        Contribution storage contribution = contributions[undineAddress][contributor];
        contribution.tributeAmount += amount; // Increase individual tribute amount
    
        // Dynamic TVL Increment
        totalValueRaised += amount;
    }

    // Retrieve Individual Tribute Amount for Specific Campaign
    function getTributeAmount(address undineAddress, address contributor) public view returns (uint256) {
        return contributions[undineAddress][contributor].tributeAmount;
    }

    // Retrieve Total Amount for Specific Campaign
    function getAmountRaised(address undineAddress) public view returns (uint256) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return campaign.amountRaised;
    }

// LIQUIDITY | 24 Hour Campaign Time Check
    function isCampaignConcluded(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return block.timestamp > campaign.endTime;
    }

// LIQUIDITY | Push LP Pair Contract Address to Campaign[]
    function archiveLPAddress(address undineAddress, address lpTokenAddress) external onlyParacelsus {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        campaign.lpTokenAddress = lpTokenAddress;

        // Event
        emit LPTokenAddressUpdated(undineAddress, lpTokenAddress);
    }

    // Retrieve LP Address for Specific Campaign
    function getLPTokenAddress(address undineAddress) public view returns (address) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return campaign.lpTokenAddress;
    }

    // Check to see if the LP has been Invoked for Specific Campaign
    function isLPInvoked(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        // Ensure the campaign exists to avoid referencing an uninitialized index
        if(index == 0 && campaigns.length > 0 && campaigns[0].undineAddress != undineAddress) {
            return false; // Index not found or invalid undineAddress
        }
        return campaigns[index].lpTokenAddress != address(0);
    }


// MEMBERSHIP CLAIM

    // Calculate Claim based on % of Supply Ownership
    function calculateClaimAmount(address undineAddress, address contributor) public {
        uint256 campaignIndex = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[campaignIndex];
        Contribution storage contribution = contributions[undineAddress][contributor];

        uint256 claimPercentage = contribution.tributeAmount * 1e18 / campaign.amountRaised; // Using 1e18 for precision
        contribution.claimAmount = 450000 * claimPercentage / 1e18; // 45% of Supply Distributed to Membership
        
        // Design Decision to Hardcode Supply to 1M tokens
            // 500k to LP
            // 450k to Distribution
            // 50k to ManaPool
    }

    // Clear after Claim
    function resetClaimAmount(address undineAddress, address contributor) external onlyParacelsus {
        contributions[undineAddress][contributor].claimAmount = 0;
    }

    // Active Claim Check
    function isClaimWindowActive(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return block.timestamp >= campaign.startClaim && block.timestamp <= campaign.endClaim;
    }

//* DOMINION | CURATION

// How EXACTLY is Dominance calculated?

//* // Calculate and Update Dominance Hierarchy | Might Need to integrate Salamander votePower or create another Function.
    function calculateDominanceAndWeights() external onlyManaPool {
        delete dominanceRankings; // Reset the dominance rankings for the new calculation
        for (uint i = 0; i < campaigns.length; i++) {
            uint256 dominancePercentage = (campaigns[i].amountRaised * 1e18) / totalValueRaised;
            dominanceRankings.push(Dominance({
                undineAddress: campaigns[i].undineAddress,
                dominancePercentage: dominancePercentage,
                manaPoolReward: 0 // Initialize manaPoolReward to 0 for each entry
            }));
            emit DominanceCalculated(campaigns[i].undineAddress, dominancePercentage);
        }
    }

//* // Calculate the ETH to be sent to each Undine | Need to integrate Salamander votePower
    function calculateRewards(uint256 manaPoolBalance) external override onlyManaPool {
        require(msg.sender == address(manaPool), "Caller must be ManaPool");

        uint256 totalDistributed = 0;
        for (uint i = 0; i < dominanceRankings.length; i++) {
            uint256 reward = (dominanceRankings[i].dominancePercentage * manaPoolBalance) / 1e18;
            dominanceRankings[i].manaPoolReward = reward;
            totalDistributed += reward;
        }

        // Handle any discrepancy between totalDistributed and manaPoolBalance if necessary
    }


// DOMINANCE UTILITIES

    // This function includes all Undine Tokens to Sell for ETH in ManaPool, via transmutePool()
    function getAllUndineAddresses() public view returns (address[] memory) {
        address[] memory undineAddresses = new address[](campaigns.length);
        for (uint i = 0; i < campaigns.length; i++) {
            undineAddresses[i] = campaigns[i].undineAddress;
        }
        return undineAddresses;
    }


    // veNFTs accept ERC20 Deposits, Only if the ERC20 is an Undine deployed by Paracelsus.
    function isUndineAddress(address _address) public view returns (bool) {
        for (uint i = 0; i < campaigns.length; i++) {
            if (campaigns[i].undineAddress == _address) {
                return true;
            }
        }
        return false;
    }

    // Retrieve DominancePercentage to Calculate Voting Power for veNFTs
    function getDominancePercentage(address undineAddress) public view returns (uint256) {
    uint256 index = campaignIndex[undineAddress];
    if (index == 0 && campaigns[0].undineAddress != undineAddress) {
        return 0;
    }
    return dominanceRankings[index].dominancePercentage;
}

    // rewardsModifier() [Campaign[]]
        // Increase amountRaised for a specific undineAddress if the manaPoolReward is Positive
        // Decrease amountRaised for a specific undineAddress if the manaPoolReward is Negative
        // Increment this during each Epoch Claim || Means I need to revisit calculateRewards() and calculateDominanceAndWeights() to include weekly Votes

}