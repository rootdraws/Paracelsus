// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Archivist.sol";
import "./ManaPool.sol";
import "./Undine.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Paracelsus is Ownable (msg.sender) {
    Archivist public archivist;
    ManaPool public manaPool;
    Undine public aetherUndine;
    address public supswapRouter;
    address public supswapFactory;

    event UndineDeployed(address indexed undineAddress, string tokenName, string tokenSymbol);

    constructor(
        address _supswapRouter,    // UniswapV2Router02 Testnet 0x5951479fE3235b689E392E9BC6E968CE10637A52
        address _supswapFactory,   // UniswapV2Factory Testnet 0x9fBFa493EC98694256D171171487B9D47D849Ba9
        string memory _tokenName,  // AetherLab
        string memory _tokenSymbol // AETHER
    ) {
        // Deploys Archivist & ManaPool with Paracelsus as their Owner
        archivist = new Archivist(address(this));
        manaPool = new ManaPool(address(this));

        supswapRouter = _supswapRouter;
        supswapFactory = _supswapFactory;

        // Deploys AETHER Undine with Paracelsus as its Owner
        aetherUndine = new Undine(
            _tokenName,
            _tokenSymbol,
            _supswapRouter,
            _supswapFactory,
            address(archivist),
            address(manaPool)
        );

        address aetherUndineAddress = address(aetherUndine);
        aetherUndine.transferOwnership(address(this));

        // Campaign Duration
        uint256 startTime = block.timestamp; // Campaign starts immediately upon contract deployment
        uint256 duration = 1 days; // Campaign concludes in 24 Hours
        uint256 endTime = startTime + duration;
        uint256 startClaim = endTime; // Claim Period begins when Campaign Ends
        uint256 claimDuration = 5 days; // Claim Period Lasts 5 Days
        uint256 endClaim = startClaim + claimDuration; 

        // Register the AETHER campaign with Archivist
        archivist.registerCampaign(
            address(aetherUndine),
            _tokenName,
            _tokenSymbol,
            address(0), // Placeholder for LP token address
            0, // Initial amount raised
            startTime,
            endTime,
            startClaim,
            endClaim
        );

        // Emit an event for AETHER Undine Launch
        emit UndineDeployed(aetherUndineAddress, _tokenName, _tokenSymbol);
    }


    // createCampaign() requires sending .01 ETH to the ManaPool, and then launches an Undine Contract.
    
    function createCampaign(
        string memory tokenName,   // Name of Token Launched
        string memory tokenSymbol  // Symbol of Token Launched

    ) public payable {
        require(msg.value == 0.01 ether, "Must deposit 0.01 ETH to ManaPool to invoke an Undine.");

        // Ensure ManaPool can accept ETH contributions
        (bool sent, ) = address(manaPool).call{value: msg.value}("");
        require(sent, "Failed to send Ether to ManaPool");

        // New Undine Deployed
        Undine newUndine = new Undine(
            tokenName,
            tokenSymbol,
            supswapRouter,
            supswapFactory,
            address(archivist),
            address(manaPool)
        );

        // Transfer ownership of the new Undine to Paracelsus
        address newUndineAddress = address(newUndine);
        newUndine.transferOwnership(address(this));

        // Initial placeholders
        address lpTokenAddress = address(0); // Placeholder for LP token address
        uint256 amountRaised = 0;            // Initial amount raised

        // Campaign Duration
        uint256 startTime = block.timestamp;
        uint256 duration = 1 days; // Campaign concludes in 24 Hours
        uint256 endTime = startTime + duration;
        uint256 startClaim = endTime;
        uint256 claimDuration = 5 days;
        uint256 endClaim = startClaim + claimDuration; 

        // Register the new campaign with Archivist
        archivist.registerCampaign(newUndineAddress, tokenName, tokenSymbol, lpTokenAddress, amountRaised, startTime, endTime, startClaim, endClaim);

        // Emit an event for the new campaign creation
        emit UndineDeployed(newUndineAddress, tokenName, tokenSymbol);
    }

    // Makes a tribute of ETH to an Undine | Pull UI from Archivist to populate undineAddress for Transaction
  function tribute(address undineAddress, uint256 amount) public payable {
        require(msg.value == amount, "Sent ETH does not match the specified amount.");
        require(archivist.isCampaignActive(undineAddress), "The campaign is not active or has concluded.");

        // Send the tribute to the Undine contract
        (bool success, ) = undineAddress.call{value: msg.value}("");
        require(success, "Failed to send Ether.");

        // Archivist is updated on Individual Contribution Amount, and total Contributed for Campaign
        archivist.addContribution(undineAddress, msg.sender, amount);
    }
    
    // creation of univ2LP by an Undine, following the campaign closure
    function invokeLP() {

    }
     
    // claimMembership() - uses the Archivist to calculate individual claim ammounts, and makes that amount availble for claim from ManaPool

    // abdication() -- Revokes Ownership | Burns Keys on Contract, so Contract is Immutable.

/*

These are meant to update the flags for each campaign -- though it's likely that only a part of them gets used, as a piece of other functions.

function concludeCampaign(address undineAddress) public onlyOwner {
    // Assume validation that the campaign exists and hasn't already concluded
    uint256 index = campaignIndex[undineAddress];
    campaigns[index].campaignConcluded = true;
    // Emit an event or perform additional logic as needed
}

function finalizeClaims(address undineAddress) public onlyOwner {
    // Similar validation as above
    uint256 index = campaignIndex[undineAddress];
    campaigns[index].claimConcluded = true;
    // Emit an event or perform additional logic as needed
}


*/

}