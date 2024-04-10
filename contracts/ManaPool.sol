// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// ManaPool is owned by Paracelsus.

contract ManaPool is Ownable, ReentrancyGuard {

// Constructor takes the Paracelsus contract address as an argument
    constructor(address paracelsus) Ownable(msg.sender) {
        require(paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        
        // Immediately transfer ownership to the Paracelsus contract
        transferOwnership(paracelsus);
    }

}