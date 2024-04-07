// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "contracts/PoolRegistry.sol";

contract PoolWarden is ERC20 {
    using Math for uint256;

    // Contracts
    IUniswapV2Router02 public supswapRouter;
    PoolRegistry public poolRegistry;
    address public supswapFactory;
    
    // yeet()
    uint256 public contributionDeadline;
    uint256 public totalContributed;
    mapping(address => uint256) public contributions;
    address[] public contributors; // Array of contributors
    
    // 1M Token Supply
    uint256 public constant MAX_SUPPLY = 1_000_000 * (10**18);
    
    // distribution() Limit
    bool public hasDistributed = false;

    // Constructor receives variables from RugFactory.sol input

    constructor(
        string memory name, // Token Name
        string memory symbol, // Token Symbol
        address _supswapRouter,  // Mode Sepolia Univ2
        address _supswapFactory, // Mode Sepolia Univ2
        address _poolRegistryAddress
    ) ERC20(name, symbol) {
        require(_poolRegistryAddress != address(0), "PoolRegistry address cannot be the zero address");
        
        _mint(address(this), MAX_SUPPLY); // PoolWarden mints supply to PoolWarden.
        supswapRouter = IUniswapV2Router02(_supswapRouter);
        supswapFactory = _supswapFactory;
        poolRegistry = PoolRegistry(_poolRegistryAddress); // Initialize the PoolRegistry instance
        contributionDeadline = block.timestamp + 1 hours; // Set a 1-hour deadline for testnet // Change to 24-hours for Mainnet
    }

    function yeet() external payable {
        require(block.timestamp <= contributionDeadline, "Contribution period has ended");
        
        // Notify the PoolRegistry of a new contribution
        poolRegistry.recordContribution(msg.sender, address(this), msg.value);
    }

    function distribution() public {
        require(!hasDistributed, "Distribution has already been executed");
        require(block.timestamp > contributionDeadline, "Contribution period has not ended");
        // Assuming there's a mechanism to ensure totalContributed > 0

        hasDistributed = true;

        // Conceptually let the registry handle the distribution data or process
        poolRegistry.triggerDistributionForCampaign(address(this));
    }

        function seedLP() public {
        
            require(hasDistributed, "Tokens must be distributed before LP deposit");

            // Since Tokens have been distributed already, the remaining supply of tokens is deposited into LP, along with all ETH.

            uint256 tokenAmount = balanceOf(address(this)); 
            uint256 ethAmount = address(this).balance;

            // Supswap Router Approval
            _approve(address(this), address(supswapRouter), tokenAmount);

            // Add liquidity to the pool
            supswapRouter.addLiquidityETH{value: ethAmount}(
                address(this),  // Token address
                tokenAmount,    // Amount of tokens to add
                0,              // Minimum amount of tokens to add, set to 0 to ignore slippage
                0,              // Minimum amount of ETH to add, set to 0 to ignore slippage
                address(this),  // Recipient of the liquidity tokens (usually the sender, in this case, this contract)
                block.timestamp // Deadline by when the transaction must complete
            );
        }
}
