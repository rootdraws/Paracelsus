// Import ethers from Hardhat package
import { ethers } from "hardhat";

async function main() {
    // Retrieve the contract factory for EpochManager
    const EpochManager = await ethers.getContractFactory("EpochManager");

    // Deploy EpochManager
    const epochManager = await EpochManager.deploy();
    await epochManager.deployed(); // Ensure the contract is fully deployed

    console.log("EpochManager deployed to:", epochManager.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
