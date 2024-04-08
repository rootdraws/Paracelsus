// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/Warden.sol";
import "contracts/Archivist.sol";

/*

DEPLOYMENT:

Consider a more monolythic deployment structure which relies heavily on the Constructor of RugFactory.

What if the Constructor of RugFactory was responsible for the following: 

1. Deploy PoolRegistry & Set Variables
2. Deploy FACTORY PoolWarden & Initiate the first campaign.

*/

contract RugFactory is Ownable(msg.sender) {
    PoolRegistry public poolRegistry;

    // Declaration of events for campaign actions

    event MaximizeMyAlpha(address indexed poolWarden, string tokenName, string tokenSymbol); 
    event CalculatingDistribution(address indexed poolWarden);
    event LpDepositTriggered(address indexed poolWarden);
    
    /* Constructor needs to deploy FACTORY POOLWARDEN. */
    /* Perms for using these functions are all going to be token gated to FACTORY owners. */

    // Constructor initializing the RugFactory with the address of PoolRegistry
    constructor(address _poolRegistryAddress) {
        require(_poolRegistryAddress != address(0), "PoolRegistry address cannot be the zero address");
        poolRegistry = PoolRegistry(_poolRegistryAddress);

        /* DEPLOY FACTORY As POOLWARDEN.0 */
    }

    // FACTORY owners get to launch new campaigns

    function createCampaign(
        string memory tokenName,   // RUGFACTORY
        string memory tokenSymbol, // FACTORY
        address supswapRouter,     // UniswapV2Router02 - 0x5951479fE3235b689E392E9BC6E968CE10637A52
        address supswapFactory     // UniswapV2Factory -  0x9fBFa493EC98694256D171171487B9D47D849Ba9 [Factory creates new LP Pairs.]
    ) public onlyOwner {   // TokenGate this function to FACTORY owners
        PoolWarden newCampaign = new PoolWarden(
            tokenName,  
            tokenSymbol, 
            supswapRouter,  
            supswapFactory,  // 
            address(this) // Pass the address of this RugFactory
        );

        // Assuming LP Token Address is determined here; this might involve additional logic
        // Placeholder for demonstration purposes
        address lpTokenAddress = address(0); // TODO: Determine the actual LP token address

        /* You ought to be able to understand what you are creating here -- and if the other mapping for contributions from individuals is different, cause you may need to seed that with empty variables as well. */

        // Register the new campaign in the PoolRegistry
        poolRegistry.registerCampaign(address(newCampaign), lpTokenAddress);

        // Emit an event to log the creation of the new campaign
        emit MaximizeMyAlpha(address(newCampaign), tokenName, tokenSymbol);
    }

    /* This calculation function is called to the PoolRegistry, and is a preparation for the claim for each campaign. */

    // Check to see if you did alright in setting up the timer for RugFactory to track each new campaign. 
    // You might actually need to create a state in the PoolRegistry, instead of just running a timer here -- that way it checks against the state, whether or not that specific poolWarden is ready to be initiating calculateDistribution()
    // Function to trigger distribution for a specific PoolWarden campaign
    function calculateDistribution(address poolWarden) public onlyOwner {
        require(poolWarden != address(0), "Invalid PoolWarden address");
        PoolRegistry(poolWarden).calculateDistribution();
        emit CalculatingDistribution(poolWarden);
    }

    /* This is a setup instruction for the LP, which takes place after Distribution.*/

    // Function to trigger the depositLP function for a specific PoolWarden campaign
    function triggerDepositLP(address poolWarden) public onlyOwner {
        require(poolWarden != address(0), "Invalid PoolWarden address");
        PoolWarden(poolWarden).seedLP();
        emit LpDepositTriggered(poolWarden);
    }

    // function abdication()
    // called after the FACTORY distribution is complete.
    // Transfers ownership to FACTORY Holders || Essentially token gating the launchpad.
}