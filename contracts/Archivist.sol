// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// Archivist is owned by Paracelsus. 
// All Write() must be sent by Paracelsus.
// Archivist stores and provides all data for Paracelsus and Undine Contracts.
// Archivist provides data for the UI | UX, to allow people to pick campaigns, join them, and execute transactions.

contract Archivist is Ownable {
    
    address public paracelsus;
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
        uint256 claimAmount; // Initially set to 0, calculated later
    }

// DOMINANCE HIERARCHY

 struct Dominance {
        address undineAddress;
        uint256 dominancePercentage;
    }

    event DominanceCalculated(address indexed undineAddress, uint256 dominancePercentage);
    
    event CampaignRegistered(address indexed undineAddress, string tokenName, string tokenSymbol);

// CONSTRUCTOR | Establishes Paracelsus as Owner
    
    constructor(address _paracelsus) {
        require(_paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        paracelsus = _paracelsus;
        
        // Immediately transfer ownership to the Paracelsus contract
        transferOwnership(paracelsus);
    }

    modifier onlyParacelsus() {
        require(msg.sender == paracelsus, "Caller is not Paracelsus");
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

        emit CampaignRegistered(_undineAddress, _tokenName, _tokenSymbol);
    }


// TRIBUTE | Campaign Active Check | Read

    function isCampaignActive(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return block.timestamp >= campaign.startTime && block.timestamp <= campaign.endTime;
    }

// TRIBUTE | TVL Incrementation | Campaign Incrementation | Individual Contribution Record | WRITE

    function addContribution(address undineAddress, address contributor, uint256 amount) external onlyParacelsus {
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

    // Retrieve the tributeAmount for a specific contributor in a given campaign | READ
    function getTributeAmount(address undineAddress, address contributor) public view returns (uint256) {
        return contributions[undineAddress][contributor].tributeAmount;
    }

    // Retrieve the total amount raised for a given campaign | READ
    function getAmountRaised(address undineAddress) public view returns (uint256) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return campaign.amountRaised;
    }

// LIQUIDITY | Campaign Conclusion Check | READ

    function isCampaignConcluded(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return block.timestamp > campaign.endTime;
    }

// LIQUIDITY | Update LP Pair Contract Address to Campaign[] | WRITE

    function archiveLPAddress(address undineAddress, address lpTokenAddress) external onlyParacelsus {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        campaign.lpTokenAddress = lpTokenAddress;

        // Emit an event for the update
        emit LPTokenAddressUpdated(undineAddress, lpTokenAddress);
    }

    // Retrieve the LP token address for a given campaign | READ
    function getLPTokenAddress(address undineAddress) public view returns (address) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return campaign.lpTokenAddress;
    }

    // Check to see if the LP has been Invoked for an Undine. | READ
    function isLPInvoked(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        // Ensure the campaign exists to avoid referencing an uninitialized index
        if(index == 0 && campaigns.length > 0 && campaigns[0].undineAddress != undineAddress) {
            return false; // Index not found or invalid undineAddress
        }
        return campaigns[index].lpTokenAddress != address(0);
    }


// MEMBERSHIP CLAIM

    // Calculate Claim based on % of Supply Ownership | READ
    function calculateClaimAmount(address undineAddress, address contributor) public {
        uint256 campaignIndex = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[campaignIndex];
        Contribution storage contribution = contributions[undineAddress][contributor];

        uint256 claimPercentage = contribution.tributeAmount * 1e18 / campaign.amountRaised; // Using 1e18 for precision
        contribution.claimAmount = 450000 * claimPercentage / 1e18; // 45% of Supply Distributed to Membership
    }

    // Clear after Claim | WRITE
    function resetClaimAmount(address undineAddress, address contributor) external onlyParacelsus {
        contributions[undineAddress][contributor].claimAmount = 0;
    }

    // Active Claim Check | READ
    function isClaimWindowActive(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        return block.timestamp >= campaign.startClaim && block.timestamp <= campaign.endClaim;
    }


// DOMINION | UNDINE LP REWARDS

    // This function gets all existing Undine Address for the transmutePool() in ManaPool
    function getAllUndineAddresses() public view returns (address[] memory) {
        address[] memory undineAddresses = new address[](campaigns.length);
        for (uint i = 0; i < campaigns.length; i++) {
            undineAddresses[i] = campaigns[i].undineAddress;
        }
        return undineAddresses;
    }

     // Calculate and update the dominance rankings
    function calculateDominanceAndWeights() external onlyOwner {
        delete dominanceRankings; // Reset the dominance rankings for the new calculation
        for (uint i = 0; i < campaigns.length; i++) {
            uint256 dominancePercentage = (campaigns[i].amountRaised * 1e18) / totalValueRaised;
            dominanceRankings.push(Dominance({
                undineAddress: campaigns[i].undineAddress,
                dominancePercentage: dominancePercentage
            }));
            emit DominanceCalculated(campaigns[i].undineAddress, dominancePercentage);
        }
    }

    // rewardsAmountRaised() [Campaign[]]
        // Increase amountRaised for a specific undineAddress
        // This amountRaised is incremented during Epoch Claims

}
