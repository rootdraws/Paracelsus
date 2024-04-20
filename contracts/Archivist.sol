// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "./ManaPool.sol";

/* 

AUTOMATION:

Automation for the Archivist is focused on calculating the Dominance Rank | manaPoolRewards for each Undine.
This Automation is triggered on a weekly cycle??

*/

contract Archivist is Ownable (msg.sender), AutomationCompatible {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public uniV2Router;
    address public paracelsus;
    ManaPool public manaPool;
    uint256 public totalValueRaised = 0;

    bool public distillationFlag;
    uint256 public lastDistillationTime;

    struct Campaign {
        address undineAddress; // Paracelsus
        string tokenName; // Paracelsus
        string tokenSymbol; // Paracelsus
        address lpTokenAddress; // Paracelsus
        uint256 amountRaised; // Paracelsus
        bool campaignOpen; // Paracelsus
        bool claimsProcessed; 
        bool claimsOpen;       
        EnumerableSet.AddressSet contributors;
    }


    struct Dominance {
        address undineAddress;
        uint256 dominancePercentage;
        uint256 manaPoolReward;
    }

    struct Contribution {
        uint256 tributeAmount;
        uint256 claimAmount;
    }

    Campaign[] private campaigns;
    Dominance[] public dominanceRankings;
    mapping(address => uint256) public campaignIndex;
    mapping(address => mapping(address => Contribution)) public contributions;

// EVENTS
    event DominanceCalculated(address indexed undineAddress, uint256 dominancePercentage);
    event CampaignRegistered(address indexed undineAddress, string tokenName, string tokenSymbol);
    event LPTokenAddressUpdated(address indexed undineAddress, address lpTokenAddress);
    event RewardsDistributed(uint256 totalDistributed);
    event CampaignStatusUpdated(address indexed undineAddress, bool isOpen);
    event ClaimsCalculated(address indexed undineAddress);
    event CampaignClaimsUpdated(address indexed undineAddress, bool campaignOpen, bool claimsOpen);

// CONSTRUCTOR
    constructor() {}

// ADDRESSES
    function setArchivistAddressBook(
        address _uniV2Router,
        address _paracelsus,
        address _manaPool
    ) external onlyOwner {
        require(_uniV2Router != address(0) && _paracelsus != address(0) && 
                _manaPool != address(0), "Invalid address");
        uniV2Router = _uniV2Router;
        paracelsus = _paracelsus;
        manaPool = ManaPool(_manaPool);
    }

// LAUNCH | REGISTRATION | Initiate Campaign Storage
    function registerCampaign(
        address _undineAddress,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _lpTokenAddress,
        uint256 _amountRaised,
        bool _campaignOpen
    ) public {
       Campaign storage campaign = campaigns.push();
        campaign.undineAddress = _undineAddress;
        campaign.tokenName = _tokenName;
        campaign.tokenSymbol = _tokenSymbol;
        campaign.lpTokenAddress = _lpTokenAddress;
        campaign.amountRaised = _amountRaised;
        campaign.campaignOpen = _campaignOpen;
        campaignIndex[_undineAddress] = campaigns.length - 1;
        emit CampaignRegistered(_undineAddress, _tokenName, _tokenSymbol);
    }

// LAUNCH | LIQUIDITY | Push LP Pair Contract Address to Campaign[]
    function archiveLPAddress(address undineAddress, address lpTokenAddress) external {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        campaign.lpTokenAddress = lpTokenAddress;

        // Event
        emit LPTokenAddressUpdated(undineAddress, lpTokenAddress);
    }

// LAUNCH | CONTRIBUTION PERIOD 24H
  function addContribution(address undineAddress, address contributor, uint256 amount) public {
        campaigns[campaignIndex[undineAddress]].contributors.add(contributor);
        Contribution storage contribution = contributions[undineAddress][contributor];
        contribution.tributeAmount += amount;
        campaigns[campaignIndex[undineAddress]].amountRaised += amount;
        totalValueRaised += amount;
    }

// LAUNCH | Pull Open Campaign to tribute()
    function getLatestOpenCampaign() public view returns (address) {
        for (uint256 i = campaigns.length; i > 0; i--) {
            if (campaigns[i-1].campaignOpen) {
                return campaigns[i-1].undineAddress;
            }
        }
        return address(0); // Return zero if no open campaigns are found
    }


// LAUNCH | CONCLUSION
    function closeCampaign(address undineAddress) public {
        require(msg.sender == paracelsus, "Only Paracelsus can close campaigns"); // Ensuring only Paracelsus can call this
        uint256 index = campaignIndex[undineAddress];
        require(index < campaigns.length, "Campaign does not exist");

        Campaign storage campaign = campaigns[index];
        campaign.campaignOpen = false;
        
        emit CampaignStatusUpdated(undineAddress, false);
    }

// LAUNCH | CHECK CLOSE
      function isCampaignOpen(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        require(index < campaigns.length, "Campaign does not exist");
        return campaigns[index].campaignOpen;
    }

// CLAIMS | DETERMINE UNPROCESSED CLAIMS
    function getUnprocessedCampaign() public view returns (address) {
    for (uint256 i = 0; i < campaigns.length; i++) {
        if (!campaigns[i].campaignOpen && !campaigns[i].claimsProcessed) {
            return campaigns[i].undineAddress;
        }
    }
    return address(0);  // Return zero address if no unprocessed campaigns are found
}

// CLAIMS | PROCESS CLAIM AMOUNTS
    function calculateClaimsForCampaign(address undineAddress) public {
        require(msg.sender == paracelsus || msg.sender == address(this), "Unauthorized access");
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        require(!campaign.claimsProcessed, "Claims already processed");

        uint256 totalAmountRaised = campaign.amountRaised;
        for (uint256 i = 0; i < campaign.contributors.length(); i++) {
            address contributor = campaign.contributors.at(i);
            uint256 tributeAmount = contributions[undineAddress][contributor].tributeAmount;
            uint256 claimPercentage = (tributeAmount * 1e18) / totalAmountRaised;
            contributions[undineAddress][contributor].claimAmount = (450000 * claimPercentage) / 1e18;
        }

        campaign.claimsProcessed = true; // Set claims as processed
        campaign.claimsOpen = true; // Optionally open claims immediately
        emit ClaimsCalculated(undineAddress);
    }

// CLAIMS | OPEN CLAIMS CHECK
    function getLatestOpenClaims() public view returns (address undineAddress) {
            for (uint256 i = 0; i < campaigns.length; i++) {
                if (campaigns[i].claimsOpen && !campaigns[i].claimsProcessed) {
                    return campaigns[i].undineAddress;
                }
            }
            return address(0);
        }

// CLAIMS | GET CLAIM AMOUNT
    function getClaimAmount(address undineAddress, address claimant) public view returns (uint256) {
        return contributions[undineAddress][claimant].claimAmount;
    }

// CLAIMS | RESET CLAIM AMOUNT
    function resetClaimAmount(address undineAddress, address claimant) public {
        contributions[undineAddress][claimant].claimAmount = 0;
    }

// CLAIMS | CLOSE CLAIMS

  function closeClaims(address undineAddress) public {
        require(msg.sender == address(manaPool), "Only ManaPool can close claims");
        require(campaignIndex[undineAddress] < campaigns.length, "Campaign does not exist");
        Campaign storage campaign = campaigns[campaignIndex[undineAddress]];
        require(campaign.claimsOpen, "Claims are already closed for this campaign");

        campaign.claimsOpen = false; // Close the claims

        emit CampaignClaimsUpdated(undineAddress, campaign.campaignOpen, false);
    }

// DOMINANCE RANK | DECAY RATE | INTERNAL
   // This is a powerful feature. It may be better to more selectively filter down. Testing may be needed.
   function applyDecay() internal {
        calculateDominanceAndWeights();  // Ensure the latest rankings are available
        uint256 decayRate = 10;  // 10% decay rate
        uint256 minimumThreshold = 1 ether;  // Set a threshold below which funds are set to 0

        // Apply decay to all campaigns
        for (uint256 i = 0; i < campaigns.length; i++) {
            uint256 decayAmount = campaigns[i].amountRaised * decayRate / 100;
            if (campaigns[i].amountRaised > decayAmount) {
                campaigns[i].amountRaised -= decayAmount;
                if (campaigns[i].amountRaised < minimumThreshold) {
                    campaigns[i].amountRaised = 0;  // Set to zero if below minimum threshold
                }
            } else {
                campaigns[i].amountRaised = 0;  // Set to zero if decay amount is greater than current amount
            }
        }
    }

// DOMINANCE RANK | DOMINANCE % | INTERNAL
    function calculateDominanceAndWeights() internal {
        uint256 totalValueRaisedTemp = 0;
        delete dominanceRankings;

        for (uint i = 0; i < campaigns.length; i++) {
            totalValueRaisedTemp += campaigns[i].amountRaised;
            uint256 dominancePercentage = (campaigns[i].amountRaised * 1e18) / totalValueRaised;
            dominanceRankings.push(Dominance({
                undineAddress: campaigns[i].undineAddress,
                dominancePercentage: dominancePercentage,
                manaPoolReward: 0
            }));
            emit DominanceCalculated(campaigns[i].undineAddress, dominancePercentage);
        }

        totalValueRaised = totalValueRaisedTemp; // Update after recalculating to avoid division by zero
    }

// DISTILLATION | CALCULATE REWARDS
    function calculateRewards(uint256 manaPoolBalance) external {
        require(msg.sender == address(manaPool), "Caller is not the ManaPool");
        
        uint256 totalDistributed = 0;

        applyDecay();  // Apply Decay and Calculate Weights before distribution.

        for (uint i = 0; i < dominanceRankings.length; i++) {
            uint256 reward = (dominanceRankings[i].dominancePercentage * manaPoolBalance) / 1e18;
            dominanceRankings[i].manaPoolReward += reward;
            totalDistributed += reward;
        }

        emit RewardsDistributed(totalDistributed);
    }



// MANAPOOL
    function getAllUndineAddresses() public view returns (address[] memory) {
        address[] memory undineAddresses = new address[](campaigns.length);
        for (uint i = 0; i < campaigns.length; i++) {
            undineAddresses[i] = campaigns[i].undineAddress;
        }
        return undineAddresses;
    }

// Function to set the distillation flag
    function setDistillationFlag(bool _flag) external {
        require(msg.sender == address(manaPool), "Only ManaPool can set the distillation flag");
        distillationFlag = _flag;
        if (_flag) {
            lastDistillationTime = block.timestamp;
        }
    }

// Function to check and reset the distillation flag
    function resetDistillationFlag() public {
        // require(msg.sender == address(manaPool), "Only ManaPool can reset the distillation flag");
        distillationFlag = false;
    }

// CHAINLINK AUTOMATION
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = distillationFlag;
        performData = "";
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata) external override {
        require(distillationFlag, "No distillation needed");
        manaPool.distillation(); // Call distillation method in ManaPool
        resetDistillationFlag(); // Ensure the flag is reset after operation
    }
}

/*

OBJECTIVE: 


CONNECTION: 

*/
