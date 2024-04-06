// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SlowRug is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    address public beneficiary;
    uint256 public start;
    uint256 public duration;
    uint256 public originalBalance;
    bool public started;

    event TokensReleased(uint256 amount);

    constructor(address _token, address _beneficiary) {
        require(_token != address(0), "Token address cannot be zero.");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero.");
        token = IERC20(_token);
        beneficiary = _beneficiary;
        duration = 365 days; // Linear vesting period of 1 year
    }

    // Function to start the vesting period manually
    function startVesting() public onlyOwner {
        require(!started, "Vesting already started.");
        started = true;
        start = block.timestamp;
        originalBalance = token.balanceOf(address(this));
    }

    // Function to release the vested tokens
    function releaseTokens() public {
        require(started, "Vesting has not started yet.");
        uint256 elapsed = block.timestamp.sub(start);
        require(elapsed <= duration, "Vesting period has already ended.");
        uint256 totalBalance = token.balanceOf(address(this));
        uint256 releasable = originalBalance.mul(elapsed).div(duration).sub(originalBalance.sub(totalBalance));
        require(releasable > 0, "No tokens are due for release yet.");

        token.transfer(beneficiary, releasable);
        emit TokensReleased(releasable);
    }

    // Function to retrieve remaining tokens after vesting period
    function retrieveExcessTokens() public onlyOwner {
        require(block.timestamp > start.add(duration), "Vesting period has not ended yet.");
        uint256 remainingBalance = token.balanceOf(address(this));
        token.transfer(owner(), remainingBalance);
    }
}
