// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "./Archivist.sol";
import "./ManaPool.sol";
import "./Undine.sol";

/* 

AUTOMATION:

Automation for Tributary Calculates Claims for the Latest Undine Campaign.
Automation is triggered 24 Hours after createCampaign(), when the most recently created Campaign has been marked Closed, by the Paracelsus Automation.

*/

contract Tributary is Ownable (msg.sender), AutomationCompatibleInterface {
    
    Archivist public archivist;
    ManaPool public manaPool;
    Undine public undine;

    event TributeMade(address indexed undineAddress, address indexed contributor, uint256 amount);

    constructor() {}

// ADDRESSES
    function setTributaryAddressBook(
        address _archivist,
        address _manaPool
        ) external {
        
        // Check Addresses
        require(_archivist != address(0), "Archivist address cannot be the zero address.");
        require(_manaPool != address(0), "ManaPool address cannot be the zero address.");
        
        // Set Addresses
        archivist = Archivist(_archivist);
        manaPool = ManaPool(_manaPool);
    }

// CONTRIBUTION | 24 Hour Window after LAUNCH to contribute ETH to your Undine.
    function tribute(uint256 amount) public payable {
        address undineAddress = archivist.getLatestOpenCampaign(); // TIMER is set by Paracelsus Automation
        require(undineAddress != address(0), "No open campaigns");
        require(amount >= 0.01 ether && amount <= 10 ether, "Deposit must be between 0.01 and 10 ETH.");
        require(msg.value == amount, "Sent ETH does not match the specified amount.");

        Undine(undineAddress).deposit{value: msg.value}();
        archivist.addContribution(undineAddress, msg.sender, amount);
        emit TributeMade(undineAddress, msg.sender, amount);
    }


// AUTOMATION | CHECK -- Return the Address of an Undine whose campaign is CLOSED, and whose claims are UNPROCESSED.
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        address unprocessedCampaign = archivist.getUnprocessedCampaign();
        return (unprocessedCampaign != address(0), abi.encode(unprocessedCampaign));
    }

// AUTOMATION | UPKEEP -- Calculate Claim Amounts for each Contributor for that Campaign, and enable claims from ManaPool.
    function performUpkeep(bytes calldata performData) external override {
        address undineAddress = abi.decode(performData, (address));
        if (undineAddress != address(0)) {  // Validate again to ensure consistency
            archivist.calculateClaimsForCampaign(undineAddress);
        }
    }
}

/*

OBJECTIVE: 

tribute() can be called for 24 Hours after Undine Launch.
When the Campaign is marked as Closed, Tributary Automation checkUpkeep() becomes valid.
performUpkeep() calculates the Claims for each contributor for that campaign, and updates an Array in the Archivist with Member Claim Amounts.

CONNECTION: 

openClaims is marked as TRUE. 

Members can Manually Claim their tokens from ManaPool for 5 Days.

*/