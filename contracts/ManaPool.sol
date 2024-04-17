// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "contracts/Archivist.sol";

contract ManaPool is Ownable (msg.sender), ReentrancyGuard {
    using Address for address payable;

    IUniswapV2Router02 public uniV2Router;
    address public paracelsus; 
    Archivist public archivist;
    address public salamander;
    address public epochManager;    

// MAPPING | UNDINE TOKEN BALANCES
    struct UndineBalances {
        mapping(address => uint256) tokenBalances; // Token address => balance
    }
    
    mapping(address => UndineBalances) private undineBalances; // Mapping from Undine addresses to their balances

// EVENTS
    event TokensClaimed(address indexed undineAddress, uint256 amount);

// CONSTRUCTOR
    constructor() {}

// ADDRESSES
    function setManaPoolAddressBook(
        address _uniV2Router,
        address _paracelsus,
        address _archivist,
        address _salamander,
        address _epochManager
        ) external onlyOwner {
        
        // Check Addresses
        require(_uniV2Router != address(0), "Univ2Router address cannot be the zero address.");
        require(_paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        require(_archivist != address(0), "Salamander address cannot be the zero address.");
        require(_salamander != address(0), "Salamander address cannot be the zero address.");
        require(_epochManager != address(0), "EpochManager address cannot be the zero address.");
        
        // Set Addresses
        uniV2Router = IUniswapV2Router02(_uniV2Router);
        paracelsus = _paracelsus;
        archivist = Archivist(_archivist);
        salamander = _salamander;
        epochManager = _epochManager;
    }

  // SECURITY
        modifier onlyParacelsus() {
            require(msg.sender == paracelsus, "Caller is not Paracelsus");
            _;
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
        emit TokensClaimed(_undineAddress, _amount);
    }

// LP REWARD | MARKET SELL 1% of TOKENS TO ETH each week
    function transmutePool() external onlyParacelsus {
        address[] memory undines = archivist.getAllUndineAddresses();
        uint256 decayRate = 1; // Assuming a decay rate of 1% for simplicity

        for (uint i = 0; i < undines.length; i++) {
            address undineAddress = undines[i];
            uint256 tokenBalance = undineBalances[undineAddress].tokenBalances[undineAddress];
            uint256 amountToSell = (tokenBalance * decayRate) / 100;

            if(amountToSell > 0) {
                IERC20(undineAddress).approve(address(uniV2Router), amountToSell);
                address[] memory path = new address[](2);
                path[0] = undineAddress;
                path[1] = uniV2Router.WETH();

                // Swap tokens for ETH
                uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        archivist.calculateDominanceAndWeights();
        uint256 currentBalance = address(this).balance;
        
        // Sends the Current Balance of ETH to the Archivist to make Calculations for Reward Amounts
        archivist.calculateRewards(currentBalance);
    }
}
