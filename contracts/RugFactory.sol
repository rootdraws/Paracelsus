// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PoolWarden.sol"; // Assume PoolWarden is in the same directory
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract RugFactory is Ownable {
    // Event for new campaign creation
    event NewCampaignCreated(address indexed poolWarden, address indexed creator);

    // Event for successful LP compounding
    event LPCompounded(address indexed lpToken, uint256 amount);

    // Store created campaigns
    address[] public campaigns;

    // Uniswap router address for creating LPs
    address public uniswapRouter;

    // Constructor
    constructor(address _uniswapRouter) Ownable(msg.sender) {
        uniswapRouter = _uniswapRouter;
    }

    // Function to create a new crowdfunding campaign
    function createCampaign(address _tokenAddress) public {
        PoolWarden newCampaign = new PoolWarden(_tokenAddress, uniswapRouter);
        campaigns.push(address(newCampaign));
        emit NewCampaignCreated(address(newCampaign), msg.sender);
    }

    // Function to compound LP tokens by any FACTORY holder
    // Simplified version: Assumes ETH is already paired with FACTORY tokens in the contract balance
    function compoundLP(IUniswapV2Pair lpToken, uint256 amountToCompound) public onlyOwner {
        // Ensure the contract has enough LP tokens to compound
        require(lpToken.balanceOf(address(this)) >= amountToCompound, "Not enough LP tokens");

        // Add liquidity to Uniswap here
        // This is a simplified placeholder logic
        // Actual implementation would interact with Uniswap contracts

        emit LPCompounded(address(lpToken), amountToCompound);
    }

    // Getter function to return all campaigns
    function getAllCampaigns() public view returns (address[] memory) {
        return campaigns;
    }
}
