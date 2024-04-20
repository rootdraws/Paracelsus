// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "./Archivist.sol";
import "./ManaPool.sol";
import "./Undine.sol";
import "./Tributary.sol";

/* 

AUTOMATION:

Automation for Paracelsus is focused on Invoking LP for the Latest Undine Campaign.
Automation is triggered 24 Hours after createCampaign().

*/

contract Paracelsus is Ownable, AutomationCompatibleInterface {
    address public uniV2Router;
    Archivist public archivist;
    ManaPool public manaPool;
    Tributary public tributary;

// AUTOMATION | Set to invokeLP() for the Undine 24 Hours after createCampaign()
    struct CampaignData {
        address undineAddress;
        uint256 startTime;
        bool lpInvoked;
        bool campaignOpen;
    }

    // Each Campaign is assigned to latestCampaign, and then deleted after Automation.
    CampaignData private latestCampaign;

    event UndineDeployed(address indexed undineAddress, string tokenName, string tokenSymbol); 

    constructor(
        address _uniV2Router,
        address _archivist,
        address _manaPool,
        address _tributary
    ) Ownable(msg.sender) {
        uniV2Router = _uniV2Router;
        archivist = Archivist(_archivist);
        manaPool = ManaPool(_manaPool);
        tributary = Tributary(_tributary);

        // Initialize addresses in other contracts
        archivist.setArchivistAddressBook(uniV2Router, address(this), address(manaPool));
        manaPool.setManaPoolAddressBook(uniV2Router, address(this), address(archivist));
        tributary.setTributaryAddressBook(address(archivist), address(manaPool));
    }

// LAUNCH | One Campaign can be called every ~ 24 Hours
    function createCampaign(string memory tokenName, string memory tokenSymbol) public {
    require(latestCampaign.undineAddress == address(0), "An active campaign is already running.");

        Undine newUndine = new Undine(
            tokenName, 
            tokenSymbol, 
            uniV2Router, 
            address(this), 
            address(archivist), 
            address(manaPool)
            );
        address newUndineAddress = address(newUndine);
        
        // Initialize latest campaign data
        latestCampaign = CampaignData({
            undineAddress: newUndineAddress,
            startTime: block.timestamp,
            lpInvoked: false,
            campaignOpen: true
        });

        // Register the new campaign with Archivist | LP Address is set to 0 on LAUNCH
        archivist.registerCampaign(newUndineAddress, tokenName, tokenSymbol, address(0), 0, true);

        emit UndineDeployed(newUndineAddress, tokenName, tokenSymbol);
    }

// AUTOMATION | Check Condition | Has it been 24 HR since createCampaign()    
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp >= latestCampaign.startTime + 1 days && !latestCampaign.lpInvoked);
        performData = abi.encode(latestCampaign.undineAddress);
        return (upkeepNeeded, performData);
    }

// AUTOMATION | If checkUpkeep is True | InvokeLP() + ArchiveLP() + closeCampaign()
   function performUpkeep(bytes calldata performData) external override {
        address undineAddress = abi.decode(performData, (address));
        require(latestCampaign.undineAddress == undineAddress && !latestCampaign.lpInvoked, "Upkeep not needed or wrong address");

        // Mark the campaign as processed for liquidity pairing
        latestCampaign.lpInvoked = true;
        latestCampaign.campaignOpen = false; // Locally closing the campaign

        // Invoke liquidity pair creation | LP Address is set within InvokeLP()
        Undine(undineAddress).invokeLiquidityPair();
        
        // Update the archival records to closeCampaign()
        archivist.closeCampaign(undineAddress); // Close the campaign in Archivist

        delete latestCampaign; // Reset latestCampaign for the next Undine Launch.
    }
}

/*

OBJECTIVE: 

Paracelsus launches an Undine.
The Camapign is signaled as Open.
There is a 24 Hour Period for that Undine to accept ETH. 
Chainlink Automation Invokes LP for that Undine after 24 Hours, pushes LP Contract to Archivist, and signals the Campaign as Closed.

CONNECTION: 

Marking the Campaign as Closed Triggers the Automation for Claims in Tributary.sol.

*/