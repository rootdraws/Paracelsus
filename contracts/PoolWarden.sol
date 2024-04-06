// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract PoolWarden is ERC20, Ownable {
    using Math for uint256;

    IUniswapV2Router02 public supswapRouter;
    address public supswapFactory;
    address public slowRug;
    uint256 public totalContributed;
    mapping(address => uint256) public contributions;
    uint256 public constant MAX_SUPPLY = 1_000_000 * (10**18); // 1 million tokens, adjust decimal as needed

    event TokensDistributed();
    event LPPairedAndDeposited(address lpPair, uint256 tokenAmount, uint256 ethAmount);

    constructor(
        string memory name,
        string memory symbol,
        address _supswapRouter,
        address _supswapFactory,
        address _slowRug
    ) ERC20(name, symbol) {
        _mint(address(this), MAX_SUPPLY); // Mint 100% of the supply to this contract
        supswapRouter = IUniswapV2Router02(_supswapRouter);
        supswapFactory = _supswapFactory;
        slowRug = _slowRug;
    }

    // Placeholder for accepting crowdfunding via RugFactory
    function acceptContribution() external payable {
        // Logic to accept ETH and track contributions
        totalContributed += msg.value;
        contributions[msg.sender] += msg.value;
    }

    // Distributes 49.5% of the supply to contributors pro-rata
    function distribution() public onlyOwner {
        require(totalContributed > 0, "No contributions made");
        uint256 distributableSupply = MAX_SUPPLY.mul(495).div(1000); // 49.5% of supply

        for (uint i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 contributionShare = contributions[contributor].div(totalContributed);
            uint256 distributableAmount = distributableSupply.mul(contributionShare);
            _transfer(address(this), contributor, distributableAmount);
        }

        emit TokensDistributed();
    }

    // Create ETH-TOKEN LP on Supswap
    function depositLP() public onlyOwner {
        uint256 tokenAmount = MAX_SUPPLY.mul(495).div(1000); // 49.5% of supply
        uint256 ethAmount = address(this).balance;

        _approve(address(this), address(supswapRouter), tokenAmount);

        // Add the liquidity
        (,, uint256 liquidity) = supswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(), // LP tokens sent to the contract owner or a designated wallet
            block.timestamp
        );

        emit LPPairedAndDeposited(address(supswapRouter), tokenAmount, ethAmount);
    }

    // Send 1% of the supply to SlowRug.sol vesting contract
    function sendToVestingContract() public onlyOwner {
        uint256 vestingAmount = MAX_SUPPLY.mul(1).div(100); // 1% of supply
        _transfer(address(this), slowRug, vestingAmount);
    }

    // Additional functions like handling contributors array, emergency withdraw, etc., can be added as needed.
}
