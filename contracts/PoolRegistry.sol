// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolRegistry is Ownable(msg.sender) {
    struct CampaignInfo {
        address poolWardenAddress; // ERC20 token address, serves as a unique identifier
        address lpTokenAddress;    // UniV2 LP token address
        uint256 totalContributed;  // Total ETH contributed
        bool hasDistributed;       // Flag for distribution status
    }

    CampaignInfo[] public campaigns;
    mapping(address => uint256) public addressToIndex; // Maps PoolWarden address to its index in the array (+1)

    event CampaignRegistered(address indexed poolWardenAddress, address indexed lpTokenAddress);
    event ContributionRecorded(address contributor, address indexed poolWardenAddress, uint256 amount);
    event DistributionTriggered(address indexed poolWardenAddress);

    function registerCampaign(address _poolWardenAddress, address _lpTokenAddress) public onlyOwner {
        require(_poolWardenAddress != address(0), "Invalid PoolWarden address");
        require(_lpTokenAddress != address(0), "Invalid LP Token address");
        require(addressToIndex[_poolWardenAddress] == 0, "Campaign already registered");

        campaigns.push(CampaignInfo({
            poolWardenAddress: _poolWardenAddress,
            lpTokenAddress: _lpTokenAddress,
            totalContributed: 0,
            hasDistributed: false
        }));

        // Use the array length as the unique identifier for easy lookup
        addressToIndex[_poolWardenAddress] = campaigns.length;

        emit CampaignRegistered(_poolWardenAddress, _lpTokenAddress);
    }

    function recordContribution(address contributor, address poolWardenAddress, uint256 amount) public {
        uint256 index = addressToIndex[poolWardenAddress];
        require(index != 0, "Campaign does not exist");

        CampaignInfo storage campaign = campaigns[index - 1];
        campaign.totalContributed += amount;

        emit ContributionRecorded(contributor, poolWardenAddress, amount);
    }

    function triggerDistributionForCampaign(address poolWardenAddress) public onlyOwner {
        uint256 index = addressToIndex[poolWardenAddress];
        require(index != 0, "Campaign does not exist");

        CampaignInfo storage campaign = campaigns[index - 1];
        require(!campaign.hasDistributed, "Distribution has already been executed");
        require(campaign.totalContributed > 0, "No contributions made");

        campaign.hasDistributed = true;

        // Actual distribution logic should be implemented here or in PoolWarden

        emit DistributionTriggered(poolWardenAddress);
    }
}
