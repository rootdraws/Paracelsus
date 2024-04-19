// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract Archivist is Ownable (msg.sender), AutomationCompatible {
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

    Campaign[] public campaigns;
    Dominance[] public dominanceRankings;
    mapping(address => uint256) public campaignIndex;
    mapping(address => mapping(address => Contribution)) public contributions;

    event DominanceCalculated(address indexed undineAddress, uint256 dominancePercentage);
    event CampaignRegistered(address indexed undineAddress, string tokenName, string tokenSymbol);
    event LPTokenAddressUpdated(address indexed undineAddress, address lpTokenAddress);
    event RewardsDistributed(uint256 totalDistributed);

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
        uint256 _amountRaised
    ) public {
        campaigns.push(Campaign({
            undineAddress: _undineAddress,
            tokenName: _tokenName,
            tokenSymbol: _tokenSymbol,
            lpTokenAddress: _lpTokenAddress,
            amountRaised: _amountRaised
        }));
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
        Contribution storage contribution = contributions[undineAddress][contributor];
        contribution.tributeAmount += amount;
        campaigns[campaignIndex[undineAddress]].amountRaised += amount;
        totalValueRaised += amount;
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
    function calculateClaimAmount(address undineAddress, address contributor) public {
        Contribution storage contribution = contributions[undineAddress][contributor];
        Campaign storage campaign = campaigns[campaignIndex[undineAddress]];
        uint256 claimPercentage = (contribution.tributeAmount * 1e18) / campaign.amountRaised;
        contribution.claimAmount = (450000 * claimPercentage) / 1e18;
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
