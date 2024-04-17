// Import ethers from Hardhat package
import { ethers } from "hardhat";

async function main() {
    // Retrieve the contract factory for ManaPool
    const ManaPool = await ethers.getContractFactory("ManaPool");

    // Deploy ManaPool
    const manaPool = await ManaPool.deploy();
    await manaPool.deployed(); // Ensure the contract is deployed

    console.log("ManaPool deployed to:", manaPool.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
