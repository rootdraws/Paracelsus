// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ManaPool is Ownable, ReentrancyGuard {
    using Address for address payable;

    address public archivist; // Archivist contract address
    address public paracelsus; // Paracelsus contract address
    IUniswapV2Router02 public supswapRouter; // Interface for Uniswap V2 Router

    // Struct for holding token balances for each Undine
    struct UndineBalances {
        mapping(address => uint256) tokenBalances; // Token address => balance
    }
    
    mapping(address => UndineBalances) public undineBalances; // Mapping from Undine addresses to their balances

    event TokensClaimed(address indexed claimant, address indexed undineAddress, uint256 amount);

    modifier onlyParacelsus() {
        require(msg.sender == paracelsus, "Caller is not Paracelsus");
        _;
    }

// CONSTRUCTOR
    constructor(address _paracelsus, address _supswapRouter, address _archivist) {
        require(_paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        require(_supswapRouter != address(0), "SupswapRouter address cannot be the zero address.");
        require(_archivist != address(0), "Archivist address cannot be the zero address.");

        paracelsus = _paracelsus;
        supswapRouter = IUniswapV2Router02(_supswapRouter);
        archivist = _archivist;

        // Transfer ownership to Paracelsus contract
        transferOwnership(_paracelsus);
    }

// ManaPool Address
    function setManaPool(address _manaPool) external onlyParacelsus {
        require(_manaPool != address(0), "ManaPool address cannot be the zero address.");
        manaPool = _manaPool;
    }

// DEPOSIT ETH | Fee for createCampaign()    
    function deposit() external payable {}

// CLAIM
    // Function is Time-Gated using Campaign[] in the archivist
    // Unclaimed Tokens are forfiet | absorbed into the ManaPool, to be LP Rewards for Undine.
    function claimTokens(address _claimant, address _undineAddress, uint256 _amount) external nonReentrant onlyParacelsus {
        uint256 balance = undineBalances[_undineAddress].tokenBalances[_undineAddress];
        require(balance >= _amount, "Insufficient balance for claim");

        undineBalances[_undineAddress].tokenBalances[_undineAddress] -= _amount;
        IERC20(_undineAddress).transfer(_claimant, _amount); // Ensure Undine contracts are ERC20

        emit TokensClaimed(_claimant, _undineAddress, _amount);
    }

// LP REWARD | MARKET SELL 1% of TOKENS TO ETH
    function transmutePool() external onlyParacelsus {
        IArchivist archivistContract = IArchivist(archivist);
        address[] memory undines = archivistContract.getAllUndineAddresses();
        uint256 decayRate = 1; // Assuming a decay rate of 1% for simplicity

        for (uint i = 0; i < undines.length; i++) {
            address undineAddress = undines[i]; // This is also the token address
            uint256 tokenBalance = undineBalances[undineAddress].tokenBalances[undineAddress];
            uint256 amountToSell = (tokenBalance * decayRate) / 100;

            if(amountToSell > 0) {
                IERC20(undineAddress).approve(address(supswapRouter), amountToSell);
                address[] memory path = new address[](2);
                path[0] = undineAddress;
                path[1] = supswapRouter.WETH();

                // Swap tokens for ETH
                supswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountToSell,
                    0, // Accept any amount of ETH
                    path,
                    address(this), // ETH received by ManaPool
                    block.timestamp + 15 minutes
                );

                undineBalances[undineAddress].tokenBalances[undineAddress] -= amountToSell;
            }
        }
    }

// LP REWARD | Calculate ETH to Distribute Per Epoch in Archivist || To Be Modified to Include Vote Escrow Tokens
    function updateRewardsBasedOnBalance() external onlyParacelsus {
        IArchivist(archivist).calculateDominanceAndWeights();
        uint256 currentBalance = address(this).balance;
        IArchivist(archivist).calculateRewards(currentBalance);
    }

// Interface for Archivist
    interface IArchivist {
        function getAllUndineAddresses() external view returns (address[] memory);
        function calculateRewards(uint256 manaPoolBalance) external;
        function calculateDominanceAndWeights() external;
    }

}
