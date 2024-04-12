// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Archivist.sol"; 

contract Salamander is Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Archivist public archivist;
    address public paracelsus;

    struct TokenData {
        address underlyingToken;            // Type of Undine Token Locked
        uint256 amountLocked;               // Amount Locked
        uint256 lockEndTime;                // 1 year from Lock Date
        uint256 dominancePercentageAtLock;  // Undine Rank of underlyingToken
        uint256 quorumPower;                // ([totalLockedPerUndine]/1000000)
        uint256 votePower;                  // ([dominancePercentageAtLock]*[quorumPower])
    }

    // Tracking total locked amounts per Undine token
    mapping(address => uint256) public totalLockedPerUndine;
    mapping(uint256 => TokenData) public tokenData;

    constructor(address _paracelsus, address _archivist) ERC721("Salamander", "veNFT") {
        require(_archivist != address(0), "Archivist address cannot be zero.");
        archivist = Archivist(_archivist);
        
        require(_paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        paracelsus = _paracelsus;

        // Transfer ownership to Paracelsus contract
        transferOwnership(_paracelsus);

    }

      modifier onlyParacelsus() {
        require(msg.sender == paracelsus, "Caller is not Paracelsus");
        _;
    }

    function lockTokens(ERC20 token, uint256 amount) external onlyParacelsus {
        require(amount > 0, "Cannot lock zero tokens");
        require(archivist.isUndineAddress(address(token)), "Token is not a valid Undine address");

        uint256 unlockTime = block.timestamp + 365 days;
        uint256 currentDominance = archivist.getDominancePercentage(address(token)); 

        totalLockedPerUndine[address(token)] += amount;
        uint256 quorumPower = totalLockedPerUndine[address(token)] * 1e18 / 1_000_000; // Assume total supply is 1M

        TokenData storage data = tokenData[_tokenIdCounter.current()];
        data.underlyingToken = address(token);
        data.amountLocked = amount;
        data.lockEndTime = unlockTime;
        data.dominancePercentageAtLock = currentDominance;
        data.quorumPower = quorumPower;

        _mint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();

        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
    }

    function unlockTokens(uint256 tokenId) external onlyParacelsus {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        TokenData storage data = tokenData[tokenId];
        require(block.timestamp >= data.lockEndTime, "The lock period has not yet expired");

        ERC20(data.underlyingToken).transfer(msg.sender, data.amountLocked);
        totalLockedPerUndine[data.underlyingToken] -= data.amountLocked; // Decrement the total locked count
        _burn(tokenId); // Removes the token

        delete tokenData[tokenId]; // Clear the data
    }

    function vote(uint256 tokenId, address targetUndine) external onlyParacelsus {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        TokenData storage data = tokenData[tokenId];

        uint256 updatedDominance = archivist.getDominancePercentage(data.underlyingToken);
        data.votePower = data.quorumPower * updatedDominance / 1e18; // Normalize after multiplication
        // Implement the voting logic here: this could involve calling another contract or logging a vote
    }

    function _floorToWeek(uint256 _t) internal pure returns (uint256) {
        return (_t / 1 weeks) * 1 weeks;
    }
}
