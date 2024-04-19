// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "./Archivist.sol";
import "./ManaPool.sol";
import "./Undine.sol";

contract Paracelsus is Ownable, AutomationCompatibleInterface {
    address public uniV2Router;
    Archivist public archivist;
    ManaPool public manaPool;

// AUTOMATION | Local Management
    struct CampaignData {
        address undineAddress;
        uint256 startTime;
        bool lpInvoked;
        bool campaignOpen;
    }

    // Each Campaign is assigned to latestCampaign, and then deleted after Automation.
    CampaignData private latestCampaign;

    event UndineDeployed(address indexed undineAddress, string tokenName, string tokenSymbol); 
    event LPPairInvoked(address indexed undineAddress, address lpTokenAddress);

    constructor(
        address _uniV2Router,
        address _archivist,
        address _manaPool
    ) Ownable(msg.sender) {
        uniV2Router = _uniV2Router;
        archivist = Archivist(_archivist);
        manaPool = ManaPool(_manaPool);
        

        // Initialize addresses in other contracts
        archivist.setArchivistAddressBook(uniV2Router, address(this), address(manaPool));
        manaPool.setManaPoolAddressBook(uniV2Router, address(this), address(archivist));
    }

    function createCampaign(string memory tokenName, string memory tokenSymbol) public {
        Undine newUndine = new Undine(tokenName, tokenSymbol, uniV2Router, address(this), address(archivist), address(manaPool));
        address newUndineAddress = address(newUndine);
        
        // Initialize latest campaign data
        latestCampaign = CampaignData({
            undineAddress: newUndineAddress,
            startTime: block.timestamp,
            lpInvoked: false,
            campaignOpen: true
        });

        // Register the new campaign with Archivist
        archivist.registerCampaign(newUndineAddress, tokenName, tokenSymbol, address(0), 0, true);

        emit UndineDeployed(newUndineAddress, tokenName, tokenSymbol);
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp >= latestCampaign.startTime + 1 days && !latestCampaign.lpInvoked);
        performData = abi.encode(latestCampaign.undineAddress);
        return (upkeepNeeded, performData);
    }

   function performUpkeep(bytes calldata performData) external override {
        address undineAddress = abi.decode(performData, (address));
        require(latestCampaign.undineAddress == undineAddress && !latestCampaign.lpInvoked, "Upkeep not needed or wrong address");

        // Mark the campaign as processed for liquidity pairing
        latestCampaign.lpInvoked = true;
        latestCampaign.campaignOpen = false; // Locally closing the campaign

        // Invoke liquidity pair creation
        Undine(undineAddress).invokeLiquidityPair();
        address lpTokenAddress = Undine(undineAddress).archiveLP();
        
        // Update the archival records
        archivist.archiveLPAddress(undineAddress, lpTokenAddress);
        archivist.closeCampaign(undineAddress); // Close the campaign in Archivist

        emit LPPairInvoked(undineAddress, lpTokenAddress);
        delete latestCampaign; // Reset latestCampaign for the next one
    }
}