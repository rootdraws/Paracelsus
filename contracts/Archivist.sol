// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "./ManaPool.sol";

/* 

AUTOMATION:

Automation for the Archivist is focused on:

1) Calls distillation() in ManaPool
2) Resetting the distillationFlag
3) Resetting the campaignInSession | Which allows new campaigns to be launched.

Distillation Flag is initially triggered by the Automation Process in the ManaPool, which Closes Claims, and Calculates Rewards.

*/

contract Archivist is Ownable (msg.sender), AutomationCompatible {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public uniV2Router;
    address public paracelsus;
    ManaPool public manaPool;
    uint256 public totalValueRaised = 0;

    bool public campaignInSession;
    bool public distillationFlag;
    uint256 public lastDistillationTime;

    struct Campaign {
        address undineAddress; 
        string tokenName; 
        string tokenSymbol; 
        address lpTokenAddress; 
        uint256 amountRaised; 
        bool campaignOpen; 
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

// ADDRESSES | AUTOMATED via Paracelsus Constructor
    function setArchivistAddressBook(
        address _uniV2Router,
        address _paracelsus,
        address _manaPool
    ) external {
        require(_uniV2Router != address(0) && _paracelsus != address(0) && 
                _manaPool != address(0), "Invalid address");
        uniV2Router = _uniV2Router;
        paracelsus = _paracelsus;
        manaPool = ManaPool(_manaPool);
    }

// LAUNCH | Called by createCampaign() in Paracelsus
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
        campaignInSession = true;
        emit CampaignRegistered(_undineAddress, _tokenName, _tokenSymbol);
    }

// LAUNCH | AUTOMATED by Paracelsus
    function archiveLPAddress(address undineAddress, address lpTokenAddress) external {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        campaign.lpTokenAddress = lpTokenAddress;

        // Event
        emit LPTokenAddressUpdated(undineAddress, lpTokenAddress);
    }

// LAUNCH | Archival Tributary Funcation
  function addContribution(address undineAddress, address contributor, uint256 amount) public {
        campaigns[campaignIndex[undineAddress]].contributors.add(contributor);
        Contribution storage contribution = contributions[undineAddress][contributor];
        contribution.tributeAmount += amount;
        campaigns[campaignIndex[undineAddress]].amountRaised += amount;
        totalValueRaised += amount;
    }

// LAUNCH | Archival Tributary Funcation
    function getLatestOpenCampaign() public view returns (address) {
        for (uint256 i = campaigns.length; i > 0; i--) {
            if (campaigns[i-1].campaignOpen) {
                return campaigns[i-1].undineAddress;
            }
        }
        return address(0); // Return zero if no open campaigns are found
    }


// LAUNCH | AUTOMATED
    function closeCampaign(address undineAddress) public {
        require(msg.sender == paracelsus, "Only Paracelsus can close campaigns"); // Ensuring only Paracelsus can call this
        uint256 index = campaignIndex[undineAddress];
        require(index < campaigns.length, "Campaign does not exist");

        Campaign storage campaign = campaigns[index];
        campaign.campaignOpen = false;
        
        emit CampaignStatusUpdated(undineAddress, false);
    }

// LAUNCH | Archival Tributary Funcation
      function isCampaignOpen(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        require(index < campaigns.length, "Campaign does not exist");
        return campaigns[index].campaignOpen;
    }

// LAUNCH | Archival Tributary Funcation
    function isCampaignInSession() public view returns (bool) {
            return campaignInSession;
        }

// LAUNCH | AUTOMATED
    function closeCampaign() public {
        campaignInSession = false; 
    }

// CLAIMS | Archival ManaPool Funcation
    function getUnprocessedCampaign() public view returns (address) {
    for (uint256 i = 0; i < campaigns.length; i++) {
        if (!campaigns[i].campaignOpen && !campaigns[i].claimsProcessed) {
            return campaigns[i].undineAddress;
        }
    }
    return address(0);  // Return zero address if no unprocessed campaigns are found
}

// CLAIMS | AUTOMATED
    function calculateClaimsForCampaign(address undineAddress) public {
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

// CLAIMS | Archival ManaPool Funcation
    function getLatestOpenClaims() public view returns (address undineAddress) {
            for (uint256 i = 0; i < campaigns.length; i++) {
                if (campaigns[i].claimsOpen && !campaigns[i].claimsProcessed) {
                    return campaigns[i].undineAddress;
                }
            }
            return address(0);
        }

// CLAIMS | Archival ManaPool Funcation
    function getClaimAmount(address undineAddress, address claimant) public view returns (uint256) {
        return contributions[undineAddress][claimant].claimAmount;
    }

// CLAIMS | Archival ManaPool Funcation
    function resetClaimAmount(address undineAddress, address claimant) public {
        contributions[undineAddress][claimant].claimAmount = 0;
    }

// CLAIMS | Archival ManaPool Funcation
  function closeClaims(address undineAddress) public {
        require(msg.sender == address(manaPool), "Only ManaPool can close claims");
        require(campaignIndex[undineAddress] < campaigns.length, "Campaign does not exist");
        Campaign storage campaign = campaigns[campaignIndex[undineAddress]];
        require(campaign.claimsOpen, "Claims are already closed for this campaign");

        campaign.claimsOpen = false; // Close the claims

        emit CampaignClaimsUpdated(undineAddress, campaign.campaignOpen, false);
    }

// DISTILLATION | AUTOMATED
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

// DISTILLATION | AUTOMATED | INTERNAL
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



// MANAPOOL | Archival ManaPool Funcation
    function getAllUndineAddresses() public view returns (address[] memory) {
        address[] memory undineAddresses = new address[](campaigns.length);
        for (uint i = 0; i < campaigns.length; i++) {
            undineAddresses[i] = campaigns[i].undineAddress;
        }
        return undineAddresses;
    }

// MANAPOOL | AUTOMATED
    function setDistillationFlag(bool _flag) external {
        require(msg.sender == address(manaPool), "Only ManaPool can set the distillation flag");
        distillationFlag = _flag;
        if (_flag) {
            lastDistillationTime = block.timestamp;
        }
    }

// ARCHIVIST | AUTOMATED
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
        closeCampaign(); // Closes Currently Open Campaign
    }
}

/*

OBJECTIVE: 

The Archivist Stores and Maintains Data related to the following: 
1) Campaign Registration
2) Campaign Claims for Individual Contributors
3) Automation Flags for the Campaign Cycle
4) Amounts Raised by each Campaign
5) Amounts Raised for Total of all Campaigns
6) Calculations for Rewards to be Distributed to Undines from ManaPool

Because the Archivist and the Automations create a type of Campaign Cycle, the distillation() will only be called when a new token has been launched. This means, the market is free to play out as it likes until the next token is launched. -- This also limits the need for LINK tokens, except during active campaign cycles.

Undine Markets will likely have greater recoveries without weekly sell pressure.

CONNECTION: 

The Archivist closes the Campaign Cycle, which allows for a new createCampaign() to be launched.
The Archivist also triggers the keeper.bendTheKnee() function, which is a regular market buy of LINK tokens for uninterrupted Automation.

*/
