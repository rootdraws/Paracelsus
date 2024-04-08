// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/PoolRegistry.sol";

// Set a timer on claims, and the people who don't claim get RugPulled by the RugPool.
// RugPool can be a Farming contract for FACTORY LP.

// 1% of all Tokens goes into RugPool on Launch
// Emission Rates are % based, and time vested Farm Emissions.
// Value is relative to pricing of the tokens being emitted.

// RugFactory is the Owner of all Ownable functions here, because it deployed RugFactory in the Constructor.

/* You might want to rename it FACTORYAdmin */

/*PoolRegistry public poolRegistry;*/


contract RugPool is Ownable(msg.sender) {
   

        function claim() public {
                uint256 amount = poolRegistry.claimable(address(this), msg.sender);
                require(amount > 0, "Nothing to claim.");

                // Transfer tokens from this contract to the msg.sender
                this.transfer(msg.sender, amount);

                // Reset claimable amount to 0
                poolRegistry.clearClaimable(address(this), msg.sender);
        }

}