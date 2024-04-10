// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// Archivist is owned by Paracelsus.

contract Archivist is Ownable {
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

    // Contributions | Nested mapping: Campaign Address => (Contributor Address => Contribution Info)
    mapping(address => mapping(address => Contribution)) public contributions;

    struct Contribution {
        uint256 tributeAmount;
        uint256 claimAmount; // Initially set to 0, calculated later
    }

    // Need to create a Dominance[] array or mapping, comparative TVL standings for each Undine, as well as staked AETHER for LP Rewards.
        // Dominance[] also tracks EPOCHs for reward distro

    event CampaignRegistered(
        address indexed undineAddress,
        string tokenName,
        string tokenSymbol
    );

    // Constructor takes the Paracelsus contract address as an argument
    constructor(address paracelsus) Ownable(msg.sender) {
        require(paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        
        // Immediately transfer ownership to the Paracelsus contract
        transferOwnership(paracelsus);
    }

    // Registration
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


// Tribute | Has Campaign Been Concluded? 
    function isCampaignActive(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return block.timestamp >= campaign.startTime && block.timestamp <= campaign.endTime;
    }
// Tribute | Add to Existential TVL of Undine Campaign | Add to Individual Contribution
    function addContribution(address undineAddress, address contributor, uint256 amount) external {
        // Assuming you have validated the campaign's active status in the calling function
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        campaign.amountRaised += amount; // Increase total amount raised for the campaign

        // Update individual contribution
        Contribution storage contribution = contributions[undineAddress][contributor];
        contribution.tributeAmount += amount; // Increase individual tribute amount
    }

    // incrementAmountRaised() [Campaign[]]
        // Increase amountRaised for a specific undineAddress
        // This amountRaised is incremented during newCampaigns and during Epoch Claims

    // setLPTokenAddress() [Campaign[]]
        // Set lpTokenAddress for a specific undineAddress

    // setIndividualContribution() [Membership[]]
        // This mapping looks like: [undineAddress] : [memberAddress] : [ individualContribution]
        // This is meant to be so that an individual can contribute toward multiple undineAddress Campaigns
    
    // membershipClaim() [Membership[]]
        // This function pulls amountRaised from [Campaign[]] and individualContribution() from [Membership[]]
        // This function then calculates [individualContribution / amountRaised] to determine the [claimPercentage var within function].
        // This function then takes the [Fixed Supply %]*[claimPercentage], and sets [claimAmount var within function].
        // This function pulls that claimAmount as the valid amount for claim, and then allows the Member to pull that amount.
        // This function then clears [individualContribution] from [Membership[]] for that [undineAddress].

    // undineRanking() [Domainance[]]
        // This function creates the rank distribution for LP Rewards from the ManaPool. 
        // This function adds the sum of all amountRaised from [Campaign[]], and sets to [totalValueLocked var within function].
        // This function divides [amountRaised] / [totalValueLocked] to derive [undineDominance], which is a percentage.
        // Function can push undineDominance[] to [Domainance[]] -- but we would need to create an array.
        // Also, this function would be called weekly, and there would be a constant change in the rankings.
        // The purpose of this [undineDominance] is to derive a base level of Reward Distribution per the weekly ManaPool Reward Contract.

    // devotion() [Domainance[]]
        // This function is about staking AETHER to multiply the Rewards for that particular EPOCH.
}
