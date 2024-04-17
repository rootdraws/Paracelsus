// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// Interface for Archivist
    interface IArchivist {
        function getAllUndineAddresses() external view returns (address[] memory);
        function calculateRewards(uint256 manaPoolBalance) external;
        function calculateDominanceAndWeights() external;
    }

contract ManaPool is Ownable (msg.sender), ReentrancyGuard {
    using Address for address payable;

    address public paracelsus;
    address public epochManager; 
    address public archivist;
    address public salamander;    
    IUniswapV2Router02 public supswapRouter;

// UNDINE TOKEN BALANCES
    struct UndineBalances {
        mapping(address => uint256) tokenBalances; // Token address => balance
    }
    
    mapping(address => UndineBalances) private undineBalances; // Mapping from Undine addresses to their balances

// EVENTS
    event TokensClaimed(address indexed claimant, address indexed undineAddress, uint256 amount);

// SECURITY
    modifier onlyParacelsus() {
        require(msg.sender == paracelsus, "Caller is not Paracelsus");
        _;
    }

// CONSTRUCTOR
    constructor(address _paracelsus, address _supswapRouter, address _epochManager ,address _archivist) {
        require(_paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        require(_supswapRouter != address(0), "SupswapRouter address cannot be the zero address.");
        require(_archivist != address(0), "Archivist address cannot be the zero address.");
        require(_epochManager != address(0), "Epoch Manager address cannot be the zero address.");

        paracelsus = _paracelsus;
        epochManager = _epochManager;
        archivist = _archivist;
        supswapRouter = IUniswapV2Router02(_supswapRouter);
        
        // Transfer ownership to Paracelsus contract
        transferOwnership(_paracelsus);
    }

// ADDRESSES
    // Salamander
    function setSalamander(address _salamander) external onlyParacelsus {
        require(_salamander != address(0), "ManaPool address cannot be the zero address.");
        salamander = _salamander;
    }

// DEPOSIT ETH | Fee for createCampaign()    
    function deposit() external payable {}

// CLAIM | Archivist manages Claim Period | Unclaimed Tokens absorbed by ManaPool
    function claimTokens(address _claimant, address _undineAddress, uint256 _amount) external nonReentrant onlyParacelsus {
        uint256 balance = undineBalances[_undineAddress].tokenBalances[_undineAddress];
        require(balance >= _amount, "Insufficient balance for claim");

        undineBalances[_undineAddress].tokenBalances[_undineAddress] -= _amount;
        IERC20(_undineAddress).transfer(_claimant, _amount);

        // Event
        emit TokensClaimed(_claimant, _undineAddress, _amount);
    }

// LP REWARD | MARKET SELL 1% of TOKENS TO ETH each week
    function transmutePool() external onlyParacelsus {
        IArchivist archivistContract = IArchivist(archivist);
        address[] memory undines = archivistContract.getAllUndineAddresses();
        uint256 decayRate = 1; // Assuming a decay rate of 1% for simplicity

        for (uint i = 0; i < undines.length; i++) {
            address undineAddress = undines[i];
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

//* LP REWARD | Calculate ETH to Distribute Per Epoch in Archivist || To Be Modified to Include Vote Escrow Tokens
    function updateRewardsBasedOnBalance() external onlyParacelsus {
//* Vote Information needs to be Set here.
        IArchivist(archivist).calculateDominanceAndWeights();
        uint256 currentBalance = address(this).balance;
        
        // Sends the Current Balance of ETH to the Archivist to make Calculations for Reward Amounts
        IArchivist(archivist).calculateRewards(currentBalance);
    }
}
