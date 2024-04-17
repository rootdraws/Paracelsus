// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract EpochManager is Ownable (msg.sender) {
    
    address public paracelsus;
    uint256 public epoch;
    uint256 public lastTransmuteTime;
    uint256 public constant WEEK = 1 weeks;
    
    event NewEpochTriggered(uint256 indexed epoch, uint256 timestamp);

    constructor(address _paracelsus) {
        lastTransmuteTime = block.timestamp;
        epoch = 1;

        paracelsus = _paracelsus;

        // Transfer ownership to Paracelsus contract
        transferOwnership(_paracelsus);
    }

   function isTransmuteAllowed() public view returns (bool) {
        return block.timestamp >= lastTransmuteTime + WEEK;
    }

    function updateEpoch() external {
        require(isTransmuteAllowed(), "Cooldown period has not passed.");
        lastTransmuteTime = block.timestamp;
        epoch += 1;

        emit NewEpochTriggered(epoch, lastTransmuteTime);
    }
}
