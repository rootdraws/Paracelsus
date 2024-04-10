// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Archivist.sol";
import "./ManaPool.sol";
import "./Undine.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Paracelsus is Ownable (msg.sender) {
    Archivist public archivist;
    ManaPool public manaPool;
    Undine public atherUndine;
    address public supswapRouter;
    address public supswapFactory;

    event UndineDeployed(address indexed undineAddress, string tokenName, string tokenSymbol);

    constructor(
        address _supswapRouter,    // UniswapV2Router02 Testnet 0x5951479fE3235b689E392E9BC6E968CE10637A52
        address _supswapFactory,    // UniswapV2Factory Testnet 0x9fBFa493EC98694256D171171487B9D47D849Ba9
        string memory _tokenName,   // AetherLab
        string memory _tokenSymbol  // AETHER
    ) {
        // Deploys Archivist, ManaPool and Undine with Paracelsus as their Owner
        archivist = new Archivist(address(this));
        manaPool = new ManaPool(address(this));

        supswapRouter = _supswapRouter;
        supswapFactory = _supswapFactory;
    
        // Deploys AETHER Undine
        aetherUndine = new Undine(
            _tokenName,
            _tokenSymbol,
            _supswapRouter,
            _supswapFactory,
            address(archivist),
            address(manaPool)
        );

        // Transfer ownership of the AETHER Undine to Paracelsus
        aetherUndine.transferOwnership(address(this));
    }

    // createCampaign() requires sending .01 ETH to the ManaPool, and then launches an Undine Contract.
    
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
            supswapFactory,
            address(archivist),
            address(manaPool)
        );

        // Transfer ownership of the new Undine to Paracelsus
        address newUndineAddress = address(newUndine);
        newUndine.transferOwnership(address(this));

        // Initial placeholders
        address lpTokenAddress = address(0); // Placeholder for LP token address
        uint256 amountRaised = 0;            // Initial amount raised

        // Register the new campaign with Archivist
        archivist.registerCampaign(newUndineAddress, tokenName, tokenSymbol, lpTokenAddress, amountRaised);

        // Emit an event for the new campaign creation
        emit UndineDeployed(newUndineAddress, tokenName, tokenSymbol);
    }

    // abdication() -- Revokes Ownership | Burns Keys on Contract, so Contract is Immutable.
    // tribute() - Makes a tribute of ETH to an Undine
    // invokeLP() - triggers the creation of univ2LP by an Undine, following the campaign closure
    // claimMembership() - uses the Archivist to calculate individual claim ammounts, and makes that amount availble for claim from ManaPool
        // Also sets an expiry on claim time, which then gets absorbed by the Mana Pool.
}