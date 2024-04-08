// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "contracts/Archivist.sol";

// Undine contracts are self-deploying ERC20s | a Claimdrop | Contract Owned Liquidity Vault.
// Undine contracts use the Registry as Data storage.
// Undine contracts use RugFactory as an Administrative Control.
// Undine contracts hold Univ2 LP which is created using the SupSwap Factory on Mode.

contract Undine is ERC20 {
    using Math for uint256;

    // Contracts
    IUniswapV2Router02 public supswapRouter;
    Archivist public archivist;
    address public supswapFactory;
    
    // Campaign parameters
    uint256 public contributionDeadline; // Deadline for contributions
    uint256 public totalContributed; // Total ETH contributed
    
    // Token parameters
    uint256 public constant MAX_SUPPLY = 1_000_000 * (10**18); // 1M Token Supply
    
    // Distribution control
    bool public hasDistributed = false; // Tracks whether distribution has occurred

    // Constructor sets up the ERC20 token and initializes contract references.
    constructor(
        string memory name, // Token Name
        string memory symbol, // Token Symbol
        address _supswapRouter, // Uniswap-like DEX Router
        address _supswapFactory, // DEX Factory for LP creation
        address _archivistAddress, // Address of the Archivist
        address _rugPool // Incentives | Claim Pool
    ) ERC20(name, symbol) {
        require(_archivistAddress != address(0), "PoolRegistry address cannot be the zero address");
        
        _mint(address(this), MAX_SUPPLY/2); // Mint Half the token supply to this contract
        _mint(address (_rugPool), MAX_SUPPLY/2); // Mint Half the token supply to the rugPool
        supswapRouter = IUniswapV2Router02(_supswapRouter);
        supswapFactory = _supswapFactory;
        poolRegistry = PoolRegistry(_poolRegistryAddress); // Initialize PoolRegistry instance
        contributionDeadline = block.timestamp + 24 hours; // Set contribution deadline
    }

    // Allows contributions until the deadline is reached.
    function tribute() external payable {
        require(block.timestamp <= contributionDeadline, "Contribution period has ended");
        require(msg.value > 0, "Contribution must be positive");

        // Record the contribution in the PoolRegistry
        poolRegistry.recordContribution(msg.sender, address(this), msg.value);

        totalContributed += msg.value; // Update the total contributions
        /* contributions[msg.sender] += msg.value; // Update the contributor's total */ // We need to undertand if this actually relates or transmits to Registry -- might be redundant.
    }
 
    // Seeds liquidity pool after distribution is complete.
    function invokeLP() public {
        require(hasDistributed, "Tokens must be distributed before LP deposit");

        uint256 tokenAmount = balanceOf(address(this)); // Tokens remaining for LP
        uint256 ethAmount = address(this).balance; // ETH contributed

        // Approve the router to spend tokens
        _approve(address(this), address(supswapRouter), tokenAmount);

        // Add liquidity to the pool
        supswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Minimum tokens
            0, // Minimum ETH
            address(this), // LP tokens are kept by the contract
            block.timestamp
        );
    }
}
