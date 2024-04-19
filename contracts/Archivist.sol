// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract Archivist is Ownable (msg.sender), AutomationCompatible {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public uniV2Router;
    address public paracelsus;
    address public manaPool;
    uint256 public totalValueRaised = 0;

    uint256 public lastUpdateTime = block.timestamp;

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

    event DominanceCalculated(address indexed undineAddress, uint256 dominancePercentage);
    event CampaignRegistered(address indexed undineAddress, string tokenName, string tokenSymbol);
    event LPTokenAddressUpdated(address indexed undineAddress, address lpTokenAddress);
    event RewardsDistributed(uint256 totalDistributed);
    event CampaignStatusUpdated(address indexed undineAddress, bool isOpen);
    event ClaimsCalculated(address indexed undineAddress);

    constructor() {}

    function setArchivistAddressBook(
        address _uniV2Router,
        address _paracelsus,
        address _manaPool
    ) external onlyOwner {
        require(_uniV2Router != address(0) && _paracelsus != address(0) && 
                _manaPool != address(0), "Invalid address");
        uniV2Router = _uniV2Router;
        paracelsus = _paracelsus;
        manaPool = _manaPool;
    }

// REGISTRATION
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

// LIQUIDITY | Push LP Pair Contract Address to Campaign[]
    function archiveLPAddress(address undineAddress, address lpTokenAddress) external {
        uint256 index = campaignIndex[undineAddress];
        Campaign storage campaign = campaigns[index];
        campaign.lpTokenAddress = lpTokenAddress;

        // Event
        emit LPTokenAddressUpdated(undineAddress, lpTokenAddress);
    }

// TRIBUTES
  function addContribution(address undineAddress, address contributor, uint256 amount) public {
        campaigns[campaignIndex[undineAddress]].contributors.add(contributor);
        Contribution storage contribution = contributions[undineAddress][contributor];
        contribution.tributeAmount += amount;
        campaigns[campaignIndex[undineAddress]].amountRaised += amount;
        totalValueRaised += amount;
    }

    // Conclude 24 Hour Tribute Period
    function closeCampaign(address undineAddress) public {
        require(msg.sender == paracelsus, "Only Paracelsus can close campaigns"); // Ensuring only Paracelsus can call this
        uint256 index = campaignIndex[undineAddress];
        require(index < campaigns.length, "Campaign does not exist");

        Campaign storage campaign = campaigns[index];
        campaign.campaignOpen = false;
        
        emit CampaignStatusUpdated(undineAddress, false);
    }

      function isCampaignOpen(address undineAddress) public view returns (bool) {
        uint256 index = campaignIndex[undineAddress];
        require(index < campaigns.length, "Campaign does not exist");
        return campaigns[index].campaignOpen;
    }

// DOMINANCE
   function applyDecay() internal {
        uint256 decayRate = 1;  // 1% decay rate per period
        for (uint256 i = 0; i < campaigns.length; i++) {
            uint256 decayAmount = campaigns[i].amountRaised * decayRate / 100;
            campaigns[i].amountRaised = campaigns[i].amountRaised > decayAmount ? campaigns[i].amountRaised - decayAmount : 0;
        }
    }

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

    function distributeRewardsBasedOnDominance() internal {
        uint256 manaPoolBalance = address(this).balance; // Assuming manaPool balance is managed in this contract
        uint256 totalDistributed = 0;

        for (uint i = 0; i < dominanceRankings.length; i++) {
            uint256 reward = (dominanceRankings[i].dominancePercentage * manaPoolBalance) / 1e18;
            dominanceRankings[i].manaPoolReward += reward;
            totalDistributed += reward;
        }

        emit RewardsDistributed(totalDistributed);
    }


    function calculateRewards(uint256 manaPoolBalance) public {
        require(msg.sender == address(manaPool), "Caller must be ManaPool");
        uint256 totalDistributed = 0;
        for (uint i = 0; i < dominanceRankings.length; i++) {
            uint256 reward = (dominanceRankings[i].dominancePercentage * manaPoolBalance) / 1e18;
            dominanceRankings[i].manaPoolReward += reward;
            totalDistributed += reward;
        }
        emit RewardsDistributed(totalDistributed);
    }

// CLAIMS
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

    function getUnprocessedCampaign() public view returns (address) {
    for (uint256 i = 0; i < campaigns.length; i++) {
        if (!campaigns[i].campaignOpen && !campaigns[i].claimsProcessed) {
            return campaigns[i].undineAddress;
        }
    }
    return address(0);  // Return zero address if no unprocessed campaigns are found
}


  function getClaimAmount(address undineAddress, address contributor) public view returns (uint256) {
        return contributions[undineAddress][contributor].claimAmount;
    }

     function resetClaimAmount(address undineAddress, address contributor) public {
        contributions[undineAddress][contributor].claimAmount = 0;
    }

// MANAPOOL
    function getAllUndineAddresses() public view returns (address[] memory) {
        address[] memory undineAddresses = new address[](campaigns.length);
        for (uint i = 0; i < campaigns.length; i++) {
            undineAddresses[i] = campaigns[i].undineAddress;
        }
        return undineAddresses;
    }

// CHAINLINK AUTOMATION
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastUpdateTime >= 1 weeks);
        performData = "";
        return (upkeepNeeded, performData);
    }

      function performUpkeep(bytes calldata) external override {
        // Applying decay before recalculating dominances
        applyDecay();
        calculateDominanceAndWeights();
        distributeRewardsBasedOnDominance();

        lastUpdateTime = block.timestamp;
    }
}

