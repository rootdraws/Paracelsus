// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "contracts/Archivist.sol";

/* 

AUTOMATION:

ManaPool closes the Claims Period, in order to absorb unclaimed tokens into the ManaPool.
Trigger: Claims Open + 5 Days.

*/

contract ManaPool is Ownable (msg.sender), ReentrancyGuard, AutomationCompatible {
    using Address for address payable;

    IUniswapV2Router02 public uniV2Router;
    address public paracelsus; 
    Archivist public archivist;
    address public latestOpenClaims;
    uint256 public latestOpenClaimsTimeStamp;

// MAPPING | UNDINE TOKEN BALANCES
    struct UndineBalances {
        mapping(address => uint256) tokenBalances; // Token address => balance
    }
    
    mapping(address => UndineBalances) private undineBalances; // Mapping from Undine addresses to their balances

// EVENTS
    event ClaimsClosed(address indexed undineAddress);
    event TokensClaimed(address indexed undineAddress, uint256 amount);

// CONSTRUCTOR
    constructor() {}

// ADDRESSES
    function setManaPoolAddressBook(
        address _uniV2Router,
        address _paracelsus,
        address _archivist
        ) external {
        
        // Check Addresses
        require(_uniV2Router != address(0), "Univ2Router address cannot be the zero address.");
        require(_paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        require(_archivist != address(0), "Archivist address cannot be the zero address.");

        // Set Addresses
        uniV2Router = IUniswapV2Router02(_uniV2Router);
        paracelsus = _paracelsus;
        archivist = Archivist(_archivist);
    }

// DEPOSIT ETH | Fee for createCampaign()    
    function deposit() external payable {}

// CLAIM | Archivist manages Claim Period | Unclaimed Tokens absorbed by ManaPool
      function claimTokens() external nonReentrant {
        address undineAddress = archivist.getLatestOpenClaims(); // Automated Timer Trigger
        require(undineAddress != address(0), "No open claims available");
        // require(block.timestamp < latestOpenClaimsTimeStamp + 5 days, "Claim period has ended"); // Redundancy.
        require(block.timestamp < latestOpenClaimsTimeStamp + 1 hours, "Claim period has ended"); // Testing


        uint256 claimAmount = archivist.getClaimAmount(undineAddress, msg.sender);
        require(claimAmount > 0, "No claim available for this address");

        require(undineBalances[undineAddress].tokenBalances[undineAddress] >= claimAmount, "Insufficient balance for claim");

        undineBalances[undineAddress].tokenBalances[undineAddress] -= claimAmount;
        IERC20(undineAddress).transfer(msg.sender, claimAmount);

        archivist.resetClaimAmount(undineAddress, msg.sender); // Reset the claim amount in Archivist

        emit TokensClaimed(undineAddress, claimAmount);
    }

// DISTILLATION | Return currentBalance of ETH in ManaPool
    function currentBalance() public view returns (uint256) {
        return address(this).balance;
    }


// DISTILLATION | MARKET SELL 5% of TOKENS Held by ManaPool TO ETH each Campaign Cycle
    function distillation() external {
        require(archivist.distillationFlag(), "Distillation not flagged");
        
        address[] memory undines = archivist.getAllUndineAddresses();
        uint256 decayRate = 5; // Assuming a decay rate of 5% for simplicity

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

// AUTOMATION | CHECK 
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
//      upkeepNeeded = (block.timestamp >= latestOpenClaimsTimeStamp + 5 days);
        upkeepNeeded = (block.timestamp >= latestOpenClaimsTimeStamp + 1 hours); // Testing

        performData = abi.encode(latestOpenClaims);
        return (upkeepNeeded, performData);
    }

     function performUpkeep(bytes calldata performData) external override {
        address undineAddress = abi.decode(performData, (address));
        require(undineAddress == latestOpenClaims, "Mismatch or outdated claim address");

        archivist.closeClaims(undineAddress);
        
        uint256 balanceToDistribute = this.currentBalance();
        archivist.calculateRewards(balanceToDistribute); // Calculates Rewards to be Distributed to Undine according to Dominance / Decay

        archivist.setDistillationFlag(true); // Trigger Distillation() Flag

        delete latestOpenClaims;
        delete latestOpenClaimsTimeStamp;

        emit ClaimsClosed(undineAddress);
    }
}

/*

OBJECTIVE: 
The ManaPool serves the following objectives: 

1) Storing 5% of Supply of each Undine Launched, to serve as a LP Rewards Pool for all Undines.
2) distillation() which converts 1% of all Undine tokens to ETH via Weekly Automation.
3) Facilitating Claims, and Closing Claims.

CONNECTION: 

Closing Claims, and Setting the Distillation Flag triggers the next Automation Process in the Archivist.

TESTING: 

Will need to reduce Claim Time from +5 Days.

*/