// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "./Archivist.sol";
import "./ManaPool.sol";
import "./Undine.sol";

contract Paracelsus is Ownable (msg.sender), AutomationCompatibleInterface {
    address public uniV2Router;
    Archivist public archivist;
    ManaPool public manaPool;

// CHAINLINK AUTOMATION | Chainlink calls invokeLiquidityPair() 24 Hours after new createCampaign()
struct CampaignData {
        address undineAddress;
        uint256 startTime;
        bool lpInvoked;
    }

    CampaignData private latestCampaign;


// EVENTS
    event UndineDeployed(address indexed undineAddress, string tokenName, string tokenSymbol); 
    event LPPairInvoked(address indexed undineAddress, address lpTokenAddress);
    
    event TributeMade(address indexed undineAddress, address indexed contributor, uint256 amount);
    event MembershipClaimed(address indexed undineAddress, uint256 claimAmount);


// CONSTRUCTOR
    constructor(
        address _uniV2Router,
        address _archivist,
        address _manaPool
    ) {
        uniV2Router = _uniV2Router;
        archivist = Archivist(_archivist);
        manaPool = ManaPool(_manaPool);

    // SET ADDRESSES    
        archivist.setArchivistAddressBook(
            uniV2Router,
            address(this),
            address(manaPool)
        );

        manaPool.setManaPoolAddressBook(
            uniV2Router,
            address(this),
            address(archivist)
        );
    }


// LAUNCH | There need to be requirements for this function, specifically around when it can be called following the InvokeLP Automation, and in consideration that for a new campaign to include veNFTs, there needs to be a new supply of NFTs created, and uploaded to Akord.
    function createCampaign(
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        
        // Deploy new Undine contract
        Undine newUndine = new Undine(
            tokenName,
            tokenSymbol,
            uniV2Router,
            address(this),
            address(archivist),
            address(manaPool)
        );

        address newUndineAddress = address(newUndine);
        
        // Placeholders for Campaign Array
        address lpTokenAddress = address(0);
        uint256 amountRaised = 0;

        // Set the latest campaign data
        latestCampaign = CampaignData({
            undineAddress: newUndineAddress,
            startTime: block.timestamp,
            lpInvoked: false
        });

        // Register the new campaign with Archivist
        archivist.registerCampaign(newUndineAddress, tokenName, tokenSymbol, lpTokenAddress, amountRaised);

        // Emit an event for the deployment of a new Undine
        emit UndineDeployed(newUndineAddress, tokenName, tokenSymbol);
    }

// CHAINLINK | InvokeLP() 24 Hours after createCampaign()
    // AUTOMATION checks to see if 1 Day has passed beyond latestCampaign.startTime
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        // upkeepNeeded = (block.timestamp >= latestCampaign.startTime + 1 days && !latestCampaign.lpInvoked); 24 Hours
        upkeepNeeded = (block.timestamp >= latestCampaign.startTime + 600 && !latestCampaign.lpInvoked); // 10 minutes for Testing
        performData = abi.encode(latestCampaign.undineAddress);
        return (upkeepNeeded, performData);
    }
    
    // AUTOMATION invokesLP Pair, and transmits address to Archivist.
    function performUpkeep(bytes calldata performData) external override {
        address undineAddress = abi.decode(performData, (address));
        require(!latestCampaign.lpInvoked && undineAddress == latestCampaign.undineAddress, "No upkeep needed");

        latestCampaign.lpInvoked = true;
        Undine(undineAddress).invokeLiquidityPair();

        // Optionally update Archivist with LP address
        address lpTokenAddress = Undine(undineAddress).archiveLP();
        archivist.archiveLPAddress(undineAddress, lpTokenAddress);

        // Emit event for LP invocation
        emit LPPairInvoked(undineAddress, lpTokenAddress);

        // Reset latestCampaign for next createCampaign()
        delete latestCampaign;
    }
}