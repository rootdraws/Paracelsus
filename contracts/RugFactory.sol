// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PoolWarden.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RugFactory is Ownable {
    // Event for logging the creation of new PoolWarden campaigns
    event NewCampaignCreated(address indexed poolWarden, address indexed creator, string tokenName, string tokenSymbol);

    // Stores addresses of all created PoolWarden campaigns
    address[] public campaigns;

    // Constructor is simplified, as the Uniswap Router address will now be passed during PoolWarden creation
    constructor() Ownable() {}

    /**
     * @dev Creates a new PoolWarden campaign (which also mints a new token)
     * @param tokenName The name of the token to be minted by the PoolWarden
     * @param tokenSymbol The symbol of the token
     * @param initialSupply The total supply of the tokens to be minted
     * @param uniswapRouter The address of the UniswapV2 Router for liquidity pool operations
     * @param slowRug The address of the SlowRug contract for vesting
     */
    function createCampaign(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        address uniswapRouter,
        address slowRug
    ) public {
        PoolWarden newCampaign = new PoolWarden(tokenName, tokenSymbol, initialSupply, uniswapRouter, slowRug);
        campaigns.push(address(newCampaign));
        emit NewCampaignCreated(address(newCampaign), msg.sender, tokenName, tokenSymbol);
    }

    // Returns a list of all PoolWarden campaign addresses created by this factory
    function getAllCampaigns() public view returns (address[] memory) {
        return campaigns;
    }
}
