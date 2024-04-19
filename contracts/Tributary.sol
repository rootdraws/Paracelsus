// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "./Archivist.sol";
import "./ManaPool.sol";
import "./Undine.sol";

contract Tributary is Ownable (msg.sender), AutomationCompatibleInterface {
    
    address public paracelsus;
    Archivist public archivist;
    ManaPool public manaPool;

// EVENTS

event TributeMade(address indexed undineAddress, address indexed contributor, uint256 amount);

// CONSTRUCTOR
    constructor() {}

// TRIBUTE | Contribute ETH to Undine | These need to facilitate 900 people to 900k users
    function tribute(address undineAddress, uint256 amount) public payable {
        // Check if the amount is within the allowed range
        require(amount >= 0.01 ether, "Minimum deposit is 0.01 ETH."); // Min should include the veNFT.
        require(amount <= 10 ether, "Maximum deposit is 10 ETH.");
        require(msg.value == amount, "Sent ETH does not match the specified amount.");


        // Assuming Undine has a deposit function to explicitly receive and track ETH
        Undine undineContract = Undine(undineAddress);
        undineContract.deposit{value: msg.value}();

        // Archivist is updated on Contribution amount for [Individual | Campaign | Total]
        archivist.addContribution(undineAddress, msg.sender, amount);

        // Event
        emit TributeMade(undineAddress, msg.sender, amount);
    }

// Automation could do processing here for Claims. // How much do people get calculations.
    function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
        // Implementation details here
        return (false, bytes(""));
    }

    function performUpkeep(bytes calldata) external override {
        // Implementation details here
    }

}