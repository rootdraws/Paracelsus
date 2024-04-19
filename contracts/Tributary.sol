// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "./Archivist.sol";
import "./ManaPool.sol";
import "./Undine.sol";

contract Tributary is Ownable (msg.sender), AutomationCompatibleInterface {
    
    Archivist public archivist;
    ManaPool public manaPool;

    event TributeMade(address indexed undineAddress, address indexed contributor, uint256 amount);

    constructor(address _archivist, address _manaPool) {
        archivist = Archivist(_archivist);
        manaPool = ManaPool(_manaPool);
    }

    function tribute(address undineAddress, uint256 amount) public payable {
        require(amount >= 0.01 ether && amount <= 10 ether, "Deposit must be between 0.01 and 10 ETH.");
        require(msg.value == amount, "Sent ETH does not match the specified amount.");
        require(archivist.isCampaignOpen(undineAddress), "Campaign is not open");

        Undine(undineAddress).deposit{value: msg.value}();
        archivist.addContribution(undineAddress, msg.sender, amount);
        emit TributeMade(undineAddress, msg.sender, amount);
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        address unprocessedCampaign = archivist.getUnprocessedCampaign();
        return (unprocessedCampaign != address(0), abi.encode(unprocessedCampaign));
    }

    function performUpkeep(bytes calldata performData) external override {
        address undineAddress = abi.decode(performData, (address));
        if (undineAddress != address(0)) {  // Validate again to ensure consistency
            archivist.calculateClaimsForCampaign(undineAddress);
        }
    }
}
