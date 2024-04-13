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

// veNFT METADATA
    struct TokenData {
        address underlyingToken;            // veNFTs can hold Underlying Tokens from any Undine
        uint256 amountLocked;               
        uint256 lockEndTime;                // veNFTs are locked for 1 Year
        uint256 dominancePercentageAtLock;  // Undine Dominance Rank
        uint256 quorumPower;                // Percentage of Undine Supply Locked
        uint256 votePower;                  // ([dominancePercentageAtLock]*[quorumPower])
    }

    // Track Percentage of Undine Supply Locked
    mapping(address => uint256) public totalLockedPerUndine;
    mapping(uint256 => TokenData) public tokenData;

// EVENT
    event TokensLocked(address indexed token, uint256 amount, uint256 unlockTime, uint256 quorumPower);
    event TokensUnlocked(uint256 indexed tokenId, address indexed token, address recipient, uint256 amount);


// CONSTRUCTOR
    constructor(address _paracelsus, address _archivist) ERC721("Salamander", "veNFT") {
        require(_archivist != address(0), "Archivist address cannot be zero.");
        require(_paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        
        archivist = Archivist(_archivist);
        paracelsus = _paracelsus;

        // Transfer ownership to Paracelsus contract
        transferOwnership(_paracelsus);

    }

// SECURITY
      modifier onlyParacelsus() {
        require(msg.sender == paracelsus, "Caller is not Paracelsus");
        _;
    }

// LOCK
    function lockTokens(ERC20 token, uint256 amount) external onlyParacelsus {
        require(amount > 0, "Cannot lock zero tokens");
        require(archivist.isUndineAddress(address(token)), "Token is not a valid Undine address");

        // Lock Time
        uint256 unlockTime = block.timestamp + 365 days;
        uint256 currentDominance = archivist.getDominancePercentage(address(token)); 

        totalLockedPerUndine[address(token)] += amount;
        uint256 quorumPower = totalLockedPerUndine[address(token)] * 1e18 / 1_000_000; // Assume total supply is 1M

        // Set veNFT Metadata
        TokenData storage data = tokenData[_tokenIdCounter.current()];
        data.underlyingToken = address(token);
        data.amountLocked = amount;
        data.lockEndTime = unlockTime;
        data.dominancePercentageAtLock = currentDominance;
        data.quorumPower = quorumPower;

        // Mint veNFT
        _mint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();

        // EVENT
        emit TokensLocked(address(token), amount, unlockTime, quorumPower);

        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
    }

// UNLOCK
    function unlockTokens(uint256 tokenId) external onlyParacelsus {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        
        TokenData storage data = tokenData[tokenId];
        require(block.timestamp >= data.lockEndTime, "The lock period has not yet expired");

        // Underlying Tokens are Returned on Lock Expiry
        ERC20(data.underlyingToken).transfer(msg.sender, data.amountLocked);
        totalLockedPerUndine[data.underlyingToken] -= data.amountLocked;
        
        // veNFT is Burned
        _burn(tokenId);

        // Event
        emit TokensUnlocked(tokenId, data.underlyingToken, msg.sender, data.amountLocked);

        delete tokenData[tokenId]; // Clear the data
    }

//VOTE
    function vote(uint256 tokenId, address targetUndine) external onlyParacelsus {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        TokenData storage data = tokenData[tokenId];

        uint256 updatedDominance = archivist.getDominancePercentage(data.underlyingToken);
        data.votePower = data.quorumPower * updatedDominance / 1e18;
//*     // VOTING LOGIC HERE
    }
}
