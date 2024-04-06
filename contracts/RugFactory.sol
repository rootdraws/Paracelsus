// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PoolWarden.sol";
import "./PoolRegistry.sol";

/*

UNIv2 Sepolia Mode

UniswapV2Factory -  0x9fBFa493EC98694256D171171487B9D47D849Ba9 [Factory creates new LP Pairs.]
UniswapV2Router02 - 0x5951479fE3235b689E392E9BC6E968CE10637A52 [Router handles transactions.]

*/

contract RugFactory is Ownable(msg.sender) {
    PoolRegistry public poolRegistry;

    // Declaration of events for campaign actions
    event MaximizeMyAlpha(address indexed poolWarden, address indexed creator, string tokenName, string tokenSymbol);
    event DistributionTriggered(address indexed poolWarden);
    event LpDepositTriggered(address indexed poolWarden);

    // Constructor initializing the RugFactory with the address of PoolRegistry
    constructor(address _poolRegistryAddress) {
        require(_poolRegistryAddress != address(0), "PoolRegistry address cannot be the zero address");
        poolRegistry = PoolRegistry(_poolRegistryAddress);
    }

    // Function to create a new PoolWarden campaign and register it in the PoolRegistry
    function createCampaign(
        string memory tokenName,
        string memory tokenSymbol,
        address supswapRouter,
        address supswapFactory
    ) public onlyOwner {
        PoolWarden newCampaign = new PoolWarden(
            tokenName,
            tokenSymbol,
            supswapRouter,
            supswapFactory,
            address(this) // Pass the address of this RugFactory
        );

        // Assuming LP Token Address is determined here; this might involve additional logic
        // Placeholder for demonstration purposes
        address lpTokenAddress = address(0); // TODO: Determine the actual LP token address

        // Register the new campaign in the PoolRegistry
        poolRegistry.registerCampaign(address(newCampaign), lpTokenAddress);

        // Emit an event to log the creation of the new campaign
        emit MaximizeMyAlpha(address(newCampaign), msg.sender, tokenName, tokenSymbol);
    }

    // Function to trigger distribution for a specific PoolWarden campaign
    function triggerDistribution(address poolWardenAddress) public onlyOwner {
        require(poolWardenAddress != address(0), "Invalid PoolWarden address");
        PoolWarden(poolWardenAddress).distribution();
        emit DistributionTriggered(poolWardenAddress);
    }

    // Function to trigger the depositLP function for a specific PoolWarden campaign
    function triggerDepositLP(address poolWardenAddress) public onlyOwner {
        require(poolWardenAddress != address(0), "Invalid PoolWarden address");
        PoolWarden(poolWardenAddress).depositLP();
        emit LpDepositTriggered(poolWardenAddress);
    }

    // Additional functionalities as needed...
}
