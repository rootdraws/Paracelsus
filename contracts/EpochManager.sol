// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

/*
CHAINLINK AUTOMATION: OPTIMISM SEPOLIA
Item Value
Registry Address: 0x881918E24290084409DaA91979A30e6f0dB52eBe
Registrar Address: 0x110Bd89F0B62EA1598FfeBF8C0304c9e58510Ee5
Payment Premium %: 50
Block Count per Turn: Not Applicable
Maximum Check Data Size: 5,000
Check Gas Limit: 10,000,000
Perform Gas Limit: 5,000,000
Maximum Perform Data Size: 2,000
Gas Ceiling Multiplier: 5
Minimum Upkeep Spend (LINK): 0.1

CHAINLINK AUTOMATION: BASE
Base mainnet
Registry Address: 0xE226D5aCae908252CcA3F6CEFa577527650a9e1e
Registrar Address: 0xD8983a340A96b9C2Bb6855E46847aE134Db71fB1
Payment Premium %: 50
Block Count per Turn: Not Applicable
Maximum Check Data Size: 5,000
Check Gas Limit: 10,000,000
Perform Gas Limit: 5,000,000
Maximum Perform Data Size: 2,000
Gas Ceiling Multiplier: 5
Minimum Upkeep Spend (LINK): 0.1
*/

contract EpochManager is Ownable (msg.sender), AutomationCompatibleInterface {
    address public paracelsus;
    uint256 public epoch;
    uint256 public lastTransmuteTime;
    uint256 public constant WEEK = 1 weeks;

    event NewEpochTriggered(uint256 indexed epoch, uint256 timestamp);

    constructor(address _paracelsus) {
        lastTransmuteTime = block.timestamp;
        epoch = 1;
        paracelsus = _paracelsus;
        transferOwnership(_paracelsus);
    }

    // This function checks if the weekly upkeep needs to be performed
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp - lastTransmuteTime) >= WEEK;
        return (upkeepNeeded, '');
    }


    // This function performs the weekly upkeep
    function performUpkeep(bytes calldata) external override {
        if ((block.timestamp - lastTransmuteTime) >= WEEK) {
            lastTransmuteTime = block.timestamp;
            epoch += 1;
            emit NewEpochTriggered(epoch, lastTransmuteTime);
            performDailyActions();
        }
    }

    
    // A private function to handle day-specific logic
    function performDailyActions() private {
        uint256 dayIndex = (block.timestamp - lastTransmuteTime) / 1 days % 7;
        // Implement day-specific actions here
    }
    

    // Checks if enough time has passed to allow a new epoch transmutation
    function isTransmuteAllowed() public view returns (bool) {
        return (block.timestamp - lastTransmuteTime) >= WEEK;
    }

    // Updates the epoch and logs the change
    function updateEpoch() public {
        epoch += 1;
        emit NewEpochTriggered(epoch, block.timestamp);
    }
}
