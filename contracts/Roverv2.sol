// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing necessary OpenZeppelin contracts for ERC20 token interaction and ownership control
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// SlowRug is designed for linear vesting of tokens to a beneficiary over time
contract Roverv2 is Ownable {
    using Math for uint256; // Math library for safe math operations

    IERC20 public token; // The token being vested
    address public beneficiary; // Who receives the tokens once vested
    uint256 public start; // When vesting starts
    uint256 public duration; // How long the vesting period lasts (e.g., 1 year)
    uint256 public originalBalance; // Original token balance at the start of vesting
    bool public started; // Whether the vesting has started

    event TokensReleased(uint256 amount); // Event for logging token releases

    // Sets up the vesting contract for a specific token and beneficiary
    constructor(address _token, address _beneficiary) Ownable(msg.sender) {
        require(_token != address(0), "Token address cannot be zero.");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero.");
        token = IERC20(_token); // The ERC20 token to be vested
        beneficiary = _beneficiary; // The recipient of vested tokens
        duration = 365 days; // Set the vesting duration to 1 year
    }

    // Allows the owner to start the vesting process
    function startVesting() public onlyOwner {
        require(!started, "Vesting already started."); // Ensure vesting hasn't already begun
        started = true; // Mark vesting as started
        start = block.timestamp; // Record the start time
        originalBalance = token.balanceOf(address(this)); // Record the original token balance
    }

    // Releases vested tokens to the beneficiary based on the elapsed time
    function releaseTokens() public {
        require(started, "Vesting has not started yet."); // Check if vesting has started
        uint256 elapsed = block.timestamp.sub(start); // Calculate elapsed time since start
        require(elapsed <= duration, "Vesting period has already ended."); // Ensure we're within the vesting period
        uint256 totalBalance = token.balanceOf(address(this)); // Current balance of tokens in the contract
        // Calculate the amount of tokens that can be released now
        uint256 releasable = originalBalance.mul(elapsed).div(duration).sub(originalBalance.sub(totalBalance));
        require(releasable > 0, "No tokens are due for release yet."); // Check if there are tokens to release

        token.transfer(beneficiary, releasable); // Transfer the releasable tokens to the beneficiary
        emit TokensReleased(releasable); // Log the release event
    }

    // Allows the owner to retrieve any remaining tokens after the vesting period ends
    function retrieveExcessTokens() public onlyOwner {
        require(block.timestamp > start.add(duration), "Vesting period has not ended yet."); // Ensure vesting period has ended
        uint256 remainingBalance = token.balanceOf(address(this)); // Get the remaining balance
        token.transfer(owner(), remainingBalance); // Transfer remaining tokens back to the owner
    }
}
