// Import ethers from Hardhat package
import { ethers } from "hardhat";

async function main() {
    // Retrieve the contract factory for Salamander
    const Salamander = await ethers.getContractFactory("Salamander");

    // Deploy Salamander
    const salamander = await Salamander.deploy();
    await salamander.deployed(); // Ensure the contract is deployed

    console.log("Salamander deployed to:", salamander.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
