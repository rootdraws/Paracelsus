// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol"; 

contract Undine is ERC20, Ownable (msg.sender) {
    IUniswapV2Router02 public uniV2Router;
    IUniswapV2Factory public uniV2Factory; 
    address public archivist;
    address public manaPool;
    address public paracelsus;

    // TOKEN SUPPLY | Distribution
    uint256 public constant TOTAL_SUPPLY = 1_000_000 * (10 ** 18);

    // Design Decision to Hardcode Supply to 1M tokens
    // 500k to LP
    // 450k to Distribution
    // 50k to ManaPool

    // CONSTRUCTOR
    constructor(
        string memory name,
        string memory symbol,
        address _uniV2Router,
        address _archivist,
        address _manaPool,
        address _paracelsus
    ) ERC20(name, symbol) {
        require(_uniV2Router != address(0), "Invalid UniV2Router address");
        require(_archivist != address(0) && _manaPool != address(0), "Invalid contract address");
        require(_paracelsus != address(0), "Paracelsus address cannot be the zero address.");

        uniV2Router = IUniswapV2Router02(_uniV2Router);
        uniV2Factory = IUniswapV2Factory(uniV2Router.factory()); // Initialize the factory from the router
        archivist = _archivist;
        manaPool = _manaPool;
        paracelsus = _paracelsus;

        // MINT | Max Supply
        _mint(address(this), TOTAL_SUPPLY / 2); // Mint 50% to Undine
        _mint(manaPool, TOTAL_SUPPLY / 2);      // Mint 50% to ManaPool
    }

    // SECURITY    
    modifier onlyParacelsus() {
        require(msg.sender == paracelsus, "Caller is not Paracelsus");
        _;
    }

    // TRIBUTE | MANAPOOL REWARD |  DEPOSIT ETH for tribute()    
    function deposit() external payable {}

    // LIQUIDITY | All ETH and TOKENS held by Undine are deposited into Univ2 LP
    function invokeLiquidityPair() external onlyParacelsus {
        uint256 ethAmount = address(this).balance; // Use the contract's entire ETH balance
        uint256 tokenAmount = balanceOf(address(this)); // Use the contract's entire token balance

        // Approve the Uniswap router to move the contract's tokens.
        _approve(address(this), address(uniV2Router), tokenAmount);

        // Add the liquidity
        uniV2Router.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            tokenAmount, // Minimum tokens transaction can revert to if there's an issue; set to tokenAmount for full balance
            ethAmount, // Minimum ETH transaction can revert to if there's an issue; set to ethAmount for full balance
            address(this),
            block.timestamp + 15 minutes
        );
    }

    // LIQUIDITY | LP Pair Contract is Read using Supswap Factory, and Returned to Paracelsus, who then forwards to the Archivist.
    function archiveLP() external view returns (address lpTokenAddress) {
        // address factory = univ2Router.factory(); // Get the Factory address from the Router // Unused Var
        address tokenA = address(this); // The token of this contract
        address tokenB = uniV2Router.WETH(); // The WETH token address
        lpTokenAddress = uniV2Factory.getPair(tokenA, tokenB);
        require(lpTokenAddress != address(0), "LP not found");
    }

    //* COMPOUND LP | Reward ETH is pulled from Mana Pool, and used to build LP
    // function compoundLP()
}
