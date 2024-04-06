// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin's Ownable contract for access control
import "@openzeppelin/contracts/access/Ownable.sol";

// RugRegistry keeps track of all crowdfunding campaigns and their details
contract WardenRegistry is Ownable {
    // Defines what info to keep for each campaign
    struct CampaignInfo {
        address campaignAddress; // The address of the campaign contract
        address creator; // Who created the campaign
        bool isActive; // Is the campaign currently active
        uint256 creationDate; // When was the campaign created
    }

    // Maps each campaign's address to its stored information
    mapping(address => CampaignInfo) public campaigns;

    // Keeps a list of all campaign addresses for easy lookup
    address[] public campaignList;

    // Events for logging actions: new campaigns and status updates
    event CampaignRegistered(address indexed campaignAddress, address indexed creator);
    event CampaignStatusUpdated(address indexed campaignAddress, bool isActive);

    // Constructor sets the owner of the contract (using Ownable)
    constructor() Ownable(msg.sender) {
        // Constructor can be empty, Ownable constructor is called to set the owner
    }
    
    // Registers a new campaign in the registry; can only be called by the owner
    function registerCampaign(address _campaignAddress, address _creator) external onlyOwner {
        // Checks for valid input
        require(_campaignAddress != address(0), "Invalid campaign address");
        require(_creator != address(0), "Invalid creator address");
        // Prevents registering the same campaign more than once
        require(campaigns[_campaignAddress].campaignAddress == address(0), "Campaign already registered");

        // Stores the campaign's details
        campaigns[_campaignAddress] = CampaignInfo({
            campaignAddress: _campaignAddress,
            creator: _creator,
            isActive: true,
            creationDate: block.timestamp
        });

        // Adds the campaign to the list for enumeration
        campaignList.push(_campaignAddress);

        // Logs the registration
        emit CampaignRegistered(_campaignAddress, _creator);
    }

    // Updates whether a campaign is active or not; only the owner can call this
    function updateCampaignStatus(address _campaignAddress, bool _isActive) external onlyOwner {
        // Checks that the campaign is registered
        require(campaigns[_campaignAddress].campaignAddress != address(0), "Campaign not registered");

        // Updates the campaign's active status
        campaigns[_campaignAddress].isActive = _isActive;

        // Logs the status update
        emit CampaignStatusUpdated(_campaignAddress, _isActive);
    }

    // Retrieves detailed info for a given campaign address
    function getCampaignInfo(address _campaignAddress) external view returns (CampaignInfo memory) {
        return campaigns[_campaignAddress];
    }

    // Returns a list of all registered campaign addresses
    function getAllCampaigns() external view returns (address[] memory) {
        return campaignList;
    }
}
