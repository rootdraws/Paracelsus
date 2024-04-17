// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Archivist.sol";  // Ensure this path is correct and the contract contains necessary functions

contract Salamander is Ownable (msg.sender), ERC721URIStorage {
    using Address for address;
    
    address public archivist;
    address public paracelsus;

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

    constructor(address _paracelsus, address _archivist) ERC721("Salamander", "veNFT") {
        require(_archivist != address(0), "Archivist address cannot be zero.");
        require(_paracelsus != address(0), "Paracelsus address cannot be the zero address.");
        archivist = _archivist;
        paracelsus = _paracelsus;
        transferOwnership(_paracelsus);
    }

    modifier onlyParacelsus() {
        require(msg.sender == paracelsus, "Caller is not Paracelsus");
        _;
    }

   function lockTokens(ERC20 token, uint256 amount) external onlyParacelsus {
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

    // TODO: VOTE FUNCTION
}
