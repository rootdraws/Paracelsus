// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract PoolWarden {
    using SafeERC20 for IERC20;

    address public owner;
    IERC20 public token;
    IUniswapV2Router02 public uniswapRouter;
    address public lpTokenAddress;

    uint256 public endOfCrowdfunding;
    bool public distributionDone = false;

    mapping(address => uint256) public contributions;
    address[] public contributors;

    event ContributionReceived(address contributor, uint256 amount);
    event DistributionCompleted();
    event LPGenerated(address lpTokenAddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier crowdfundingActive() {
        require(block.timestamp < endOfCrowdfunding, "Crowdfunding period ended");
        _;
    }

    modifier crowdfundingEnded() {
        require(block.timestamp >= endOfCrowdfunding, "Crowdfunding period not ended");
        _;
    }

    constructor(address _tokenAddress, address _uniswapRouterAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
        endOfCrowdfunding = block.timestamp + 24 hours;
    }

    function contribute() external payable crowdfundingActive {
        require(msg.value > 0, "Contribution must be greater than 0");
        contributions[msg.sender] += msg.value;
        contributors.push(msg.sender);
        emit ContributionReceived(msg.sender, msg.value);
    }

    function distribution() public onlyOwner crowdfundingEnded {
        require(!distributionDone, "Distribution already completed");

        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 ethBalance = address(this).balance;

        // Distributing 50% of tokens pro-rata to contributors
        for (uint i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 contributionShare = contributions[contributor] / ethBalance;
            uint256 tokensToDistribute = tokenBalance * 0.5 * contributionShare;
            token.safeTransfer(contributor, tokensToDistribute);
        }

        // Adding 50% of tokens and 100% ETH to LP
        token.safeApprove(address(uniswapRouter), tokenBalance * 0.5);
        uniswapRouter.addLiquidityETH{value: ethBalance}(
            address(token),
            tokenBalance * 0.5,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

        distributionDone = true;
        emit DistributionCompleted();
    }

    // Dummy implementations for simplicity
    function poolFees() public {
        // Implement logic to handle pool fees
    }

    function rageRug() public {
        // Implement logic for rageRug feature
    }

    // Helper to get the list of contributors (for external queries)
    function getContributors() external view returns (address[] memory) {
        return contributors;
    }
}
