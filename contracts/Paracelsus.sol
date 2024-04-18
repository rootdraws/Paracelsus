// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "./Archivist.sol";
import "./ManaPool.sol";
import "./Salamander.sol";
import "./Undine.sol";

contract Paracelsus is Ownable (msg.sender), AutomationCompatibleInterface {
    address public uniV2Router;
    Archivist public archivist;
    ManaPool public manaPool;
    Salamander public salamander;

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
        address _manaPool,
        address _salamander
    ) {
        uniV2Router = _uniV2Router;
        archivist = Archivist(_archivist);
        manaPool = ManaPool(_manaPool);
        salamander = Salamander(_salamander);

    // SET ADDRESSES    
        archivist.setArchivistAddressBook(
            uniV2Router,
            address(this),
            address(manaPool),
            address(salamander)
        );

        manaPool.setManaPoolAddressBook(
            uniV2Router,
            address(this),
            address(archivist),
            address(salamander)
        );

        salamander.setSalamanderAddressBook(
            uniV2Router,
            address(this),
            address(archivist),
            address(manaPool)
        );
    }


// LAUNCH | There need to be requirements for this function.
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
            address(manaPool),
            address(salamander)
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


// TRIBUTE | Contribute ETH to Undine
    function tribute(address undineAddress, uint256 amount) public payable {
        // Check if the amount is within the allowed range
        require(amount >= 0.01 ether, "Minimum deposit is 0.01 ETH.");
        require(amount <= 10 ether, "Maximum deposit is 10 ETH.");
        require(msg.value == amount, "Sent ETH does not match the specified amount.");

        // Assuming Undine has a deposit function to explicitly receive and track ETH
        Undine undineContract = Undine(undineAddress);
        undineContract.deposit{value: msg.value}();

        // Archivist is updated on Contribution amount for [Individual | Campaign | Total]
        archivist.addContribution(undineAddress, msg.sender, amount);

        // Event
        emit TributeMade(undineAddress, msg.sender, amount);
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