// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// Archivist is owned by Paracelsus.
// Archivist stores and provides all data for Paracelsus and Undine Contracts.
// Archivist provides data for the UI | UX, to allow people to pick campaigns, join them, and execute transactions.

contract Archivist is Ownable {
    
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
    mapping(address => uint256) public campaignIndex;

// CONTRIBUTIONS

    // Nested mapping: Campaign Address => (Contributor Address => Contribution Info)
    mapping(address => mapping(address => Contribution)) public contributions;

    struct Contribution {
        uint256 tributeAmount;
        uint256 claimAmount; // Initially set to 0, calculated later
    }

// DOMINANCE HIERARCHY

    // Need to create a Dominance[] array or mapping, comparative TVL standings for each Undine, as well as staked AETHER for LP Rewards.
    // Dominance[] also tracks EPOCHs for reward distro

    event CampaignRegistered(
        address indexed undineAddress,
        string tokenName,
        string tokenSymbol
    );

// CONSTRUCTOR | Establishes Paracelsus as Owner
    
    constructor(address paracelsus) Ownable(msg.sender) {
        require(paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        
        // Immediately transfer ownership to the Paracelsus contract
        transferOwnership(paracelsus);
    }

// REGISTRATION | Registers New Instances of Undine | New Campaigns

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
    ) external onlyOwner {
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

        emit CampaignRegistered(_undineAddress, _tokenName, _tokenSymbol);
    }


// TRIBUTE | Campaign Active Check

    function isCampaignActive(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return block.timestamp >= campaign.startTime && block.timestamp <= campaign.endTime;
    }

// TRIBUTE | Add to Existential TVL of Undine Campaign | Add to Individual Contribution

    function addContribution(address undineAddress, address contributor, uint256 amount) external {
        // Assuming you have validated the campaign's active status in the calling function
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        campaign.amountRaised += amount; // Increase total amount raised for the campaign

        // Update individual contribution
        Contribution storage contribution = contributions[undineAddress][contributor];
        contribution.tributeAmount += amount; // Increase individual tribute amount
    
        // Dynamically increase the total value raised across all campaigns
        totalValueRaised += amount;
    }

    // Retrieve the tributeAmount for a specific contributor in a given campaign
    function getTributeAmount(address undineAddress, address contributor) public view returns (uint256) {
        return contributions[undineAddress][contributor].tributeAmount;
    }

    // Retrieve the total amount raised for a given campaign
    function getAmountRaised(address undineAddress) public view returns (uint256) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return campaign.amountRaised;
    }

// LIQUIDITY | Campaign Conclusion Check

    function isCampaignConcluded(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return block.timestamp > campaign.endTime;
    }

// LIQUIDITY | Update LP Pair Contract Address to Campaign[]

    function archiveLPAddress(address undineAddress, address lpTokenAddress) external {
        // Ensure that only authorized entities can update the LP address
        // For example, you might require that the caller is the owner or the specific Undine contract itself
        require(msg.sender == owner || isAuthorizedUpdater(msg.sender), "Not authorized to update LP address");

        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        campaign.lpTokenAddress = lpTokenAddress;

        // Emit an event for the update
        emit LPTokenAddressUpdated(undineAddress, lpTokenAddress);
    }

    // Retrieve the LP token address for a given campaign
    function getLPTokenAddress(address undineAddress) public view returns (address) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return campaign.lpTokenAddress;
    }

    // Check to see if the LP has been Invoked for an Undine.
    function isLPInvoked(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        // Ensure the campaign exists to avoid referencing an uninitialized index
        if(index == 0 && campaigns.length > 0 && campaigns[0].undineAddress != undineAddress) {
            return false; // Index not found or invalid undineAddress
        }
        return campaigns[index].lpTokenAddress != address(0);
    }


// MEMBERSHIP CLAIM

    // Calculate Claim based on % of 
    function calculateClaimAmount(address undineAddress, address contributor) public {
        uint256 campaignIndex = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[campaignIndex];
        Contribution storage contribution = contributions[undineAddress][contributor];

        uint256 claimPercentage = contribution.tributeAmount * 1e18 / campaign.amountRaised; // Using 1e18 for precision
        contribution.claimAmount = 450000 * claimPercentage / 1e18; // 45% of Supply Distributed to Membership
    }

    // Clear after Claim
    function resetClaimAmount(address undineAddress, address contributor) external {
        require(msg.sender == address(paracelsusContract), "Only Paracelsus can reset claim amount.");
        contributions[undineAddress][contributor].claimAmount = 0;
    }

    // Active Claim Check
    function isClaimWindowActive(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return block.timestamp >= campaign.startClaim && block.timestamp <= campaign.endClaim;
    }


// DOMINION | UNDINE LP REWARDS

    function calculateDominanceAndWeights() external {
        // Logic to calculate TVL for each Undine
        // Adjust calculations based on votes
        // This might involve reading data from both the Archivist and ManaPool
    }


    // undineRanking() [Domainance[]]
        // This function creates the rank distribution for LP Rewards from the ManaPool. 
        // This function divides [amountRaised] / [totalValueRaised] to derive [undineDominance], which is a percentage.
        // Function can push undineDominance[] to [Domainance[]] -- but we would need to create an array.
        // Also, this function would be called weekly, and there would be a constant change in the rankings.
        // The purpose of this [undineDominance] is to derive a base level of Reward Distribution per the weekly ManaPool Reward Contract.

    // rewardsAmountRaised() [Campaign[]]
        // Increase amountRaised for a specific undineAddress
        // This amountRaised is incremented during Epoch Claims

    // devotion() [Domainance[]]
        // This function is about staking AETHER to multiply the Rewards for that particular EPOCH.
}
