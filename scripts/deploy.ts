// Import ethers from Hardhat package
import { ethers } from "hardhat";

async function main() {
    // Retrieve the contract factories
    const Archivist = await ethers.getContractFactory("Archivist");
    const ManaPool = await ethers.getContractFactory("ManaPool");
    const Salamander = await ethers.getContractFactory("Salamander");
    const EpochManager = await ethers.getContractFactory("EpochManager");
    const Paracelsus = await ethers.getContractFactory("Paracelsus");

    // Deploy contracts
    const archivist = await Archivist.deploy();
    const epochManager = await EpochManager.deploy();
    const manaPool = await ManaPool.deploy();
    const salamander = await Salamander.deploy();
    
    // Address for the Supswap Router - replace with the actual address you're using
    const supswapRouter = "0x5951479fE3235b689E392E9BC6E968CE10637A52"; // Testnet Univ2 Router on Mode

    // Deploy Paracelsus with Supswap Router address
    const paracelsus = await Paracelsus.deploy(supswapRouter);

    console.log("Archivist deployed to:", archivist.address);
    console.log("ManaPool deployed to:", manaPool.address);
    console.log("Salamander deployed to:", salamander.address);
    console.log("EpochManager deployed to:", epochManager.address);
    console.log("Paracelsus deployed to:", paracelsus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
