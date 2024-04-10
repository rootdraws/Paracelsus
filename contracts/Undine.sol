// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Undine is owned by Paracelsus.

contract Undine is ERC20, Ownable {
    address public supswapRouter;
    address public supswapFactory;
    address public archivist;
    address public manaPool;

// Total Supply of 1M tokens [18 decimals]
    uint256 public constant TOTAL_SUPPLY = 1_000_000 * (10 ** 18);

    constructor(
        string memory name, 
        string memory symbol,
        address _supswapRouter,
        address _supswapFactory,
        address _archivist,
        address _manaPool
    ) ERC20(name, symbol) Ownable(msg.sender) {

        require(_supswapRouter != address(0) && _supswapFactory != address(0), "Invalid SupSwap address");
        require(_archivist != address(0) && _manaPool != address(0), "Invalid contract address");

        supswapRouter = _supswapRouter;
        supswapFactory = _supswapFactory;
        archivist = _archivist;
        manaPool = _manaPool;

    // Mint 100% of the Supply
        _mint(address(this), TOTAL_SUPPLY / 2); // Mint 50% of the supply to Undine
        _mint(manaPool, TOTAL_SUPPLY / 2);      // Mint 50% of the supply to ManaPool
    }
    
    // - Interaction with SupSwap for liquidity purposes
    
    
    // - Interaction with Archivist and ManaPool for campaign and reward management

    // Claim Rewards from ManaPool
    function absorbManaPool() public {

    }
}
