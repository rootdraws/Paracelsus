// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// RugFactory is the Administrator | Owner of the Archivist

contract Archivist is Ownable(msg.sender) {
    
    struct CampaignInfo {
        address warden;
        address lpToken;
        uint256 totalRaised;
        bool hasDistributed;
    }
    
    // Tracks an Individual accross multiple campaigns.
    struct Participant {
        uint256 totalContributions;
        mapping(address => uint256) contributions; // Warden address to contribution amount
    }

    CampaignInfo[] public campaigns; // Array of all campaigns
    mapping(address => uint256) public addressToIndex; // Maps Warden address to its index in the array (+1)
    mapping(address => Participant) public participants; // Maps participant address to their contribution details
    mapping(address => mapping(address => uint256)) public claimable; // Campaign -> Contributor -> Amount

    // Events to log key actions within the contract.
    event CampaignRegistered(address indexed warden, address indexed lpToken);
    event ContributionRecorded(address contributor, address indexed warden, uint256 amount);
    event ClaimPrepared(address indexed warden);

    // Registers a new campaign with associated PoolWarden and LP token addresses.
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

            addressToIndex[_poolWarden] = campaigns.length; // Assign new campaign's index
            emit CampaignRegistered(_poolWarden, _lpToken);
        }

        // Records a contribution to a specific campaign, updating both the campaign's and the participant's records.

        // Can you explain exactly what is happening here -- How is the Participant and contribution amount being stored here, or mapped? 
        function recordContribution(address contributor, address _poolWarden, uint256 amount) public {
            uint256 index = addressToIndex[_poolWarden];
            require(index != 0, "Campaign does not exist");

            CampaignInfo storage campaign = campaigns[index - 1];
            campaign.totalRaised += amount;

            Participant storage participant = participants[contributor];
            participant.totalContributions += amount;
            participant.contributions[_poolWarden] += amount; // Map contribution to the specific PoolWarden campaign

            emit ContributionRecorded(contributor, _poolWarden, amount);
        }

        function calculateDistribution(address _poolWarden) internal {
        // Logic to calculate distribution amounts based on contributions
        // Update the `claimable` mapping with calculated amounts
        // Again, how does the updating work here? 
        emit ClaimPrepared(_poolWarden);
    }
        function clearClaimable() internal {
            //  A little post claim hygiene.
        }
}
