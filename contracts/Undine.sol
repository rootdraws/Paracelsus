// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "./Archivist.sol";

contract Undine is ERC20, Ownable (msg.sender), AutomationCompatible {
    IUniswapV2Router02 public uniV2Router;
    IUniswapV2Factory public uniV2Factory; 
    address public paracelsus;
    Archivist public archivist;
    address public manaPool;
    address public lpTokenAddress;

// SUPPLY
    uint256 public constant TOTAL_SUPPLY = 1_000_000 * (10 ** 18);

// EVENT
    event LPPairInvoked(address indexed undineAddress, address lpTokenAddress);
    event LPCompounded(address indexed undineAddress, address lpTokenAddress);

    constructor(
        string memory name,
        string memory symbol,
        address _uniV2Router,
        address _paracelsus,
        address _archivist,
        address _manaPool
    ) ERC20(name, symbol) {
        require(_uniV2Router != address(0) && _paracelsus != address(0) && 
                _archivist != address(0) && _manaPool != address(0), "Invalid address");

        uniV2Router = IUniswapV2Router02(_uniV2Router);
        uniV2Factory = IUniswapV2Factory(uniV2Router.factory());
        paracelsus = _paracelsus;
        archivist = Archivist(_archivist);
        manaPool = _manaPool;

        _mint(address(this), TOTAL_SUPPLY / 2);
        _mint(manaPool, TOTAL_SUPPLY / 2);
    }

    function deposit() external payable {}

    function invokeLiquidityPair() external {
    uint256 ethAmount = address(this).balance;
    uint256 tokenAmount = balanceOf(address(this));

    _approve(address(this), address(uniV2Router), tokenAmount);
    uniV2Router.addLiquidityETH{ value: ethAmount }(
        address(this),
        tokenAmount,
        0, // Minimum tokens
        0, // Minimum ETH
        address(this),
        block.timestamp + 15 minutes
    );

    // Update lpTokenAddress statefully
    lpTokenAddress = uniV2Factory.getPair(address(this), uniV2Router.WETH());
    require(lpTokenAddress != address(0), "LP not found");

    // Notify Archivist about the LP token address
    archivist.archiveLPAddress(address(this), lpTokenAddress);

    emit LPPairInvoked(address(this), lpTokenAddress);
}


    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (address(this).balance > 0 && lpTokenAddress != address(0));
        performData = "";
        return (upkeepNeeded, performData);
    }


    function performUpkeep(bytes calldata) external override {
        require(address(this).balance > 0, "No ETH available");
        require(lpTokenAddress != address(0), "LP token address not set");

        uint256 ethBalance = address(this).balance;
        uint256 halfEth = ethBalance / 2;

        // Setup token swap path
        address[] memory path = new address[](2);
        path[0] = uniV2Router.WETH();
        path[1] = address(this);

        // Swap half of the ETH for tokens
        uint256 tokenAmountBeforeSwap = balanceOf(address(this));
        uniV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: halfEth}(
            0, // Handle slippage in your contract logic
            path,
            address(this),
            block.timestamp + 15 minutes
        );

        uint256 tokensReceived = balanceOf(address(this)) - tokenAmountBeforeSwap;

        // Approve and add liquidity
        _approve(address(this), address(uniV2Router), tokensReceived);
        uniV2Router.addLiquidityETH{value: halfEth}(
            address(this),
            tokensReceived,
            0, // Adjust to handle slippage
            0,
            owner(), // Or another address
            block.timestamp + 15 minutes
        );

        emit LPCompounded(address(this), lpTokenAddress);
    }
}