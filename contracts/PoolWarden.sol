// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./PoolRegistry.sol"; // Ensure this import path is accurate

/*

UNIv2 Sepolia Mode

UniswapV2Factory -  0x9fBFa493EC98694256D171171487B9D47D849Ba9 [Factory creates new LP Pairs.]
UniswapV2Router02 - 0x5951479fE3235b689E392E9BC6E968CE10637A52 [Router handles transactions.]

*/

contract PoolWarden is ERC20 {
    using Math for uint256;

    IUniswapV2Router02 public supswapRouter;
    address public supswapFactory;
    PoolRegistry public poolRegistry; // PoolRegistry contract instance
    uint256 public contributionDeadline;
    uint256 public totalContributed;
    mapping(address => uint256) public contributions;
    address[] public contributors; // Array of contributors
    uint256 public constant MAX_SUPPLY = 1_000_000 * (10**18); // 1 million tokens with 18 decimal places
    bool public hasDistributed = false; // Flag to ensure distribution happens only once

    event TokensDistributed();
    event MaximizeMyAlpha(); // Event emitted at contract creation
    event LPPairedAndDeposited(address lpPair, uint256 tokenAmount, uint256 ethAmount);

    constructor(
        string memory name,
        string memory symbol,
        address _supswapRouter,
        address _supswapFactory,
        address _poolRegistryAddress // Address of the PoolRegistry
    ) ERC20(name, symbol) {
        require(_poolRegistryAddress != address(0), "PoolRegistry address cannot be the zero address");
        
        _mint(address(this), MAX_SUPPLY); // Mint all tokens to this contract initially
        supswapRouter = IUniswapV2Router02(_supswapRouter);
        supswapFactory = _supswapFactory;
        poolRegistry = PoolRegistry(_poolRegistryAddress); // Initialize the PoolRegistry instance
        contributionDeadline = block.timestamp + 24 hours; // Set a 24-hour deadline for contributions
    }

    function yeet() external payable {
        require(block.timestamp <= contributionDeadline, "Contribution period has ended");
        totalContributed += msg.value;
        contributions[msg.sender] += msg.value;
        contributors.push(msg.sender);
    }

    function distribution() public {
        require(!hasDistributed, "Distribution has already been executed");
        require(block.timestamp > contributionDeadline, "Contribution period has not ended");
        require(totalContributed > 0, "No contributions made");

        hasDistributed = true;

        uint256 distributableSupply = MAX_SUPPLY / 2;

        for (uint i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 contributorETH = contributions[contributor];

            // Calculate contribution percentage for each contributor
            uint256 contributionPercentage = contributorETH * 1e18 / totalContributed;
            uint256 tokensForContributor = distributableSupply * contributionPercentage / 1e18;

            _transfer(address(this), contributor, tokensForContributor);
        }

        emit TokensDistributed();

        // Additional step: Update PoolRegistry to reflect the distribution completion
        // This might require adding a new function in PoolRegistry to handle such updates
    }

    function depositLP() public {
        require(hasDistributed, "Tokens must be distributed before LP deposit");

        uint256 tokenAmount = balanceOf(address(this)); // Use remaining tokens for LP
        uint256 ethAmount = address(this).balance; // Use all contributed ETH for LP

        _approve(address(this), address(supswapRouter), tokenAmount);

        (,, uint256 liquidity) = supswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this), // Keep the LP tokens in the PoolWarden contract
            block.timestamp
        );

        emit LPPairedAndDeposited(address(supswapRouter), tokenAmount, ethAmount);

        // Notify PoolRegistry about the LP deposit
        // This step would require PoolRegistry to have a function that can be called here to update any relevant information
    }

    // Additional functionalities as needed...
}
