// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// PoolRegistry is owned by RugFactory.sol
contract PoolRegistry is Ownable(msg.sender) {
    // Structure for storing campaign information
    struct CampaignInfo {
        address poolWarden; // ERC20 Address | LP Holder
        address lpToken;    // UniV2 LP Address
        uint256 totalRaised; // Total ETH raised for the campaign
        bool hasDistributed; // Status flag indicating whether distribution has occurred
    }

    CampaignInfo[] public campaigns; // Dynamic array of all campaigns
    mapping(address => uint256) public addressToIndex; // Mapping from PoolWarden address to its index in the campaigns array (+1)

    // Events to signal important contract actions
    event CampaignRegistered(address indexed poolWarden, address indexed lpToken);
    event ContributionRecorded(address contributor, address indexed poolWarden, uint256 amount);
    event DistributionTriggered(address indexed poolWarden);

    // Registers a new campaign in the registry
    function registerCampaign(address _poolWarden, address _lpToken) public onlyOwner {
        require(_poolWarden != address(0), "Invalid PoolWarden address");
        require(_lpToken != address(0), "Invalid LP Token address");
        require(addressToIndex[_poolWarden] == 0, "Campaign already registered");

        campaigns.push(CampaignInfo({
            poolWarden: _poolWarden,
            lpToken: _lpToken,
            totalRaised: 0,
            hasDistributed: false
        }));

        addressToIndex[_poolWarden] = campaigns.length; // Map PoolWarden address to the new campaign's index

        emit CampaignRegistered(_poolWarden, _lpToken);
    }

    // Records contributions during yeet()
    function recordContribution(address contributor, address _poolWarden, uint256 amount) public {
        uint256 index = addressToIndex[_poolWarden];
        require(index != 0, "Campaign does not exist");

        CampaignInfo storage campaign = campaigns[index - 1];
        campaign.totalRaised += amount; // Increment the total raised by the amount contributed

        emit ContributionRecorded(contributor, _poolWarden, amount);
    }

   // Triggers the distribution phase for a specific campaign
function triggerDistributionForCampaign(address _poolWarden) public onlyOwner {
    uint256 index = addressToIndex[_poolWarden];
    require(index != 0, "Campaign does not exist");

    CampaignInfo storage campaign = campaigns[index - 1];
    // Verify the _poolWarden address matches the campaign's poolWarden address
    require(campaign.poolWarden == _poolWarden, "Address does not match the registered campaign");

    require(!campaign.hasDistributed, "Distribution has already been executed");
    require(campaign.totalRaised > 0, "No contributions made");

    campaign.hasDistributed = true; // Set the distribution flag to true

    emit DistributionTriggered(_poolWarden);
}

}
