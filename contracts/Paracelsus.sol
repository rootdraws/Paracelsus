// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Archivist.sol";
import "./ManaPool.sol";
import "./Undine.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Paracelsus is Ownable (msg.sender) {
    Archivist public archivist;
    ManaPool public manaPool;
    Undine public aetherUndine;
    address public supswapRouter;

    event UndineDeployed(address indexed undineAddress, string tokenName, string tokenSymbol);

// CONSTRUCTOR | Deploy Archivist + ManaPool + AETHER Undine

    constructor(
        address _supswapRouter,    // UniswapV2Router02 Testnet 0x5951479fE3235b689E392E9BC6E968CE10637A52
        string memory _tokenName,  // AetherLab
        string memory _tokenSymbol // AETHER
    ) {
        // Deploys Archivist & ManaPool with Paracelsus as their Owner
        archivist = new Archivist(address(this));
        manaPool = new ManaPool(address(this));

        supswapRouter = _supswapRouter;

        // Deploys AETHER Undine with Paracelsus as its Owner
        aetherUndine = new Undine(
            _tokenName,
            _tokenSymbol,
            _supswapRouter,
            address(archivist),
            address(manaPool)
        );

        address aetherUndineAddress = address(aetherUndine);
        aetherUndine.transferOwnership(address(this));

        // Campaign Duration
        uint256 startTime = block.timestamp; // Campaign starts immediately upon contract deployment
        uint256 duration = 1 days; // Campaign concludes in 24 Hours
        uint256 endTime = startTime + duration;
        uint256 startClaim = endTime; // Claim Period begins when Campaign Ends
        uint256 claimDuration = 5 days; // Claim Period Lasts 5 Days
        uint256 endClaim = startClaim + claimDuration; 

        // Register the AETHER campaign with Archivist
        archivist.registerCampaign(
            address(aetherUndine),
            _tokenName,
            _tokenSymbol,
            address(0), // Placeholder for LP token address
            0, // Initial amount raised
            startTime,
            endTime,
            startClaim,
            endClaim
        );

        // Emit an event for AETHER Undine Launch
        emit UndineDeployed(aetherUndineAddress, _tokenName, _tokenSymbol);
    }


// LAUNCH | createCampaign() requires sending .01 ETH to the ManaPool, and then launches an Undine Contract.
    
    function createCampaign(
        string memory tokenName,   // Name of Token Launched
        string memory tokenSymbol  // Symbol of Token Launched

    ) public payable {
        require(msg.value == 0.01 ether, "Must deposit 0.01 ETH to ManaPool to invoke an Undine.");

        // Ensure ManaPool can accept ETH contributions
        (bool sent, ) = address(manaPool).call{value: msg.value}("");
        require(sent, "Failed to send Ether to ManaPool");

        // New Undine Deployed
        Undine newUndine = new Undine(
            tokenName,
            tokenSymbol,
            supswapRouter,
            address(archivist),
            address(manaPool)
        );

        // Transfer ownership of the new Undine to Paracelsus
        address newUndineAddress = address(newUndine);
        newUndine.transferOwnership(address(this));

        // Initial placeholders
        address lpTokenAddress = address(0); // Placeholder for LP token address
        uint256 amountRaised = 0;            // Initial amount raised

        // Campaign Duration
        uint256 startTime = block.timestamp;
        uint256 duration = 1 days; // Campaign concludes in 24 Hours
        uint256 endTime = startTime + duration;
        uint256 startClaim = endTime;
        uint256 claimDuration = 5 days;
        uint256 endClaim = startClaim + claimDuration; 

        // Register the new campaign with Archivist
        archivist.registerCampaign(newUndineAddress, tokenName, tokenSymbol, lpTokenAddress, amountRaised, startTime, endTime, startClaim, endClaim);

        // Emit an event for the new campaign creation
        emit UndineDeployed(newUndineAddress, tokenName, tokenSymbol);
    }

// TRIBUTE |  Contribute ETH to Undine
  function tribute(address undineAddress, uint256 amount) public payable {
        require(msg.value == amount, "Sent ETH does not match the specified amount.");
        require(archivist.isCampaignActive(undineAddress), "The campaign is not active or has concluded.");

        // Send the tribute to the Undine contract
        (bool success, ) = undineAddress.call{value: msg.value}("");
        require(success, "Failed to send Ether.");

        // Archivist is updated on Individual Contribution Amount, and total Contributed for Campaign
        archivist.addContribution(undineAddress, msg.sender, amount);
    }
    
// LIQUIDITY | Create Univ2 LP to be Held by Undine
   function invokeLP(address undineAddress) external {
        require(msg.sender == owner(), "Only the owner can invoke LP creation.");
        require(archivist.isCampaignConcluded(undineAddress), "Campaign is still active.");

        // Forms LP from Entire Balance of ETH and ERC20 held by Undine [50% of Supply]
        IUndine(undineAddress).invokeLiquidityPair();

        // Pull LP Address from Undine via Supswap Factory
        address lpTokenAddress = IUndine(undineAddress).archiveLP();

        // Update Archivist with the LP Address for Campaign[]
        archivist.archiveLPAddress(undineAddress, lpTokenAddress);
    }

// CLAIM | Claim tokens held by ManaPool
    function claim(address undineAddress) external {}


// OWNERSHIP
    function abdication() {}
    // abdication() -- Revokes Ownership | Burns Keys on Contract, so Contract is Immutable.
}
