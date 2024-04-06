// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RugRegistry is Ownable {
    struct CampaignInfo {
        address campaignAddress;
        address creator;
        bool isActive;
        uint256 creationDate;
    }

    // Mapping from campaign address to campaign details
    mapping(address => CampaignInfo) public campaigns;

    // List of all campaigns for enumeration
    address[] public campaignList;

    event CampaignRegistered(address indexed campaignAddress, address indexed creator);
    event CampaignStatusUpdated(address indexed campaignAddress, bool isActive);

    // Function to register a new campaign in the registry
    function registerCampaign(address _campaignAddress, address _creator) external onlyOwner {
        require(_campaignAddress != address(0), "Invalid campaign address");
        require(_creator != address(0), "Invalid creator address");
        require(campaigns[_campaignAddress].campaignAddress == address(0), "Campaign already registered");

        campaigns[_campaignAddress] = CampaignInfo({
            campaignAddress: _campaignAddress,
            creator: _creator,
            isActive: true,
            creationDate: block.timestamp
        });

        campaignList.push(_campaignAddress);

        emit CampaignRegistered(_campaignAddress, _creator);
    }

    // Function to update the active status of a campaign
    function updateCampaignStatus(address _campaignAddress, bool _isActive) external onlyOwner {
        require(campaigns[_campaignAddress].campaignAddress != address(0), "Campaign not registered");

        campaigns[_campaignAddress].isActive = _isActive;

        emit CampaignStatusUpdated(_campaignAddress, _isActive);
    }

    // Function to get campaign details by address
    function getCampaignInfo(address _campaignAddress) external view returns (CampaignInfo memory) {
        return campaigns[_campaignAddress];
    }

    // Function to get all registered campaigns
    function getAllCampaigns() external view returns (address[] memory) {
        return campaignList;
    }
}
