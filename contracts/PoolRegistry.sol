// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PoolRegistry is Ownable {
    struct CampaignInfo {
        uint256 campaignId;
        address poolWardenAddress;
        address lpTokenAddress;
    }

    struct Participant {
        bool hasParticipated;
        uint256 campaignsContributed;
    }

    CampaignInfo[] public campaigns;
    mapping(address => uint256) public campaignToId;
    mapping(uint256 => address) public idToLpToken;
    mapping(address => Participant) public participants;

    uint256 public nextCampaignId = 1;

    event CampaignRegistered(uint256 indexed campaignId, address indexed poolWardenAddress, address indexed lpTokenAddress);

    constructor() Ownable(msg.sender) {} // Corrected constructor for Ownable

    function registerCampaign(address _poolWardenAddress, address _lpTokenAddress) public onlyOwner {
        require(_poolWardenAddress != address(0), "Invalid PoolWarden address");
        require(_lpTokenAddress != address(0), "Invalid LP Token address");

        CampaignInfo memory newCampaign = CampaignInfo({
            campaignId: nextCampaignId,
            poolWardenAddress: _poolWardenAddress,
            lpTokenAddress: _lpTokenAddress
        });

        campaigns.push(newCampaign);
        campaignToId[_poolWardenAddress] = nextCampaignId;
        idToLpToken[nextCampaignId] = _lpTokenAddress;

        emit CampaignRegistered(nextCampaignId, _poolWardenAddress, _lpTokenAddress);

        nextCampaignId++;
    }

    function getLpTokenAddress(uint256 _campaignId) public view returns (address) {
        require(_campaignId > 0 && _campaignId < nextCampaignId, "Campaign ID out of range");
        return idToLpToken[_campaignId];
    }

    function getCampaignInfo(uint256 _campaignId) public view returns (CampaignInfo memory) {
        require(_campaignId > 0 && _campaignId < nextCampaignId, "Campaign ID out of range");
        return campaigns[_campaignId - 1];
    }

    function getAllCampaigns() public view returns (CampaignInfo[] memory) {
        return campaigns;
    }

    // Potential functions to add for participant tracking
    // function recordParticipantContribution(...) { ... }
    // function getParticipantInfo(address participantAddress) public view returns (Participant memory) { ... }
}
