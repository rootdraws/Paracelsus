// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "contracts/Archivist.sol";

/* 

// veNFT Manifold Extension:

Salamander is a veNFT Extension for Manifold.
Salamander is passed to Factory Instanciated extension contracts which control Tribal Minting for each Undine. 

Each tribute() comes with an NFT.

The veNFT Extension holds a Mapping for what TokenID is associated with what ERC20, and for how long.
The veNFT Extension also handles Voting Logic, and Quorum Power. 
Quorum Power is calculated here, and then transmitted to the Archivist for Integration into Final Rewards.

By using Manifold Extensions, we create a singular contract, with multiple extensions, and allow for custom branded iteration, meaning that campaigns require Akord Collections, and there is a fixed number of people who can buy into each campaign, because there is a fixed number of NFTs with custom art. 

Since each Undine Release comes with its own NFT set, we can control the TokenURI for each set, and have Custom Commissioned pieces. 

We can also have DAO Owned Sudoswap LP for the entire collection.

// ON SUPPLY: 

These NFTs can probably sustain a 777 SUPPLY per contract, but the ERC20 Holders need to be able to scale up to 1M. This means that the veNFTs are going to be a managerial class.
*/


contract Salamander is Ownable (msg.sender), ERC721URIStorage {
    using Address for address;
    
    address public uniV2Router;
    address public paracelsus;
    address public archivist;
    address public manaPool;
    
    uint256 private _tokenIdCounter = 1;  // Initialize to 1 if you want to start counting from 1

    struct TokenData {
        address underlyingToken;
        uint256 amountLocked;
        uint256 lockEndTime;                // veNFTs are locked for 1 Year
        uint256 dominancePercentageAtLock;  // Undine Dominance Rank
        uint256 quorumPower;                // Percentage of Undine Supply Locked
        uint256 votePower;
    }

    mapping(address => uint256) public totalLockedPerUndine;
    mapping(uint256 => TokenData) public tokenData;

    event TokensLocked(address indexed token, uint256 amount, uint256 unlockTime, uint256 quorumPower);
    event TokensUnlocked(uint256 indexed tokenId, address indexed token, address recipient, uint256 amount);

    constructor() ERC721("Salamander", "veNFT") {}

  // ADDRESSES
    function setSalamanderAddressBook(
        address _uniV2Router,
        address _paracelsus,
        address _archivist,
        address _manaPool
        ) external {
        
        // Check Addresses
        require(_uniV2Router != address(0), "Univ2Router address cannot be the zero address.");
        require(_paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        require(_archivist != address(0), "Archivist address cannot be the zero address.");
        require(_manaPool != address(0), "ManaPool address cannot be the zero address.");
        
        // Set Addresses
        uniV2Router = _uniV2Router;
        paracelsus = _paracelsus;
        archivist = _archivist;
        manaPool = _manaPool;
    }

//LOCK
   function lockTokens(ERC20 token, uint256 amount) external {
        require(amount > 0, "Cannot lock zero tokens");

        // Correcting type casting to use functions from the Archivist contract
        Archivist archivistContract = Archivist(archivist);
        require(archivistContract.isUndineAddress(address(token)), "Token is not a valid Undine address");
        uint256 unlockTime = block.timestamp + 365 days;
        uint256 currentDominance = archivistContract.getDominancePercentage(address(token));
        
        totalLockedPerUndine[address(token)] += amount;
        uint256 quorumPower = totalLockedPerUndine[address(token)] * 1e18 / 1_000_000;
        
        TokenData storage data = tokenData[_tokenIdCounter];
        data.underlyingToken = address(token);
        data.amountLocked = amount;
        data.lockEndTime = unlockTime;
        data.dominancePercentageAtLock = currentDominance;
        data.quorumPower = quorumPower;
        
        _mint(msg.sender, _tokenIdCounter);
        _tokenIdCounter++;
        
        emit TokensLocked(address(token), amount, unlockTime, quorumPower);
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
    }

//UNLOCK
    function unlockTokens(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        TokenData storage data = tokenData[tokenId];
        require(block.timestamp >= data.lockEndTime, "The lock period has not yet expired");
        ERC20(data.underlyingToken).transfer(msg.sender, data.amountLocked);
        totalLockedPerUndine[data.underlyingToken] -= data.amountLocked;
        _burn(tokenId);
        emit TokensUnlocked(tokenId, data.underlyingToken, msg.sender, data.amountLocked);
        delete tokenData[tokenId];
    }

// TODO: VOTE FUNCTION | ALSO USE EPOCH MANAGER FOR SETTING TIMES FOR VOTES
}
