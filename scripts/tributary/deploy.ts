// Import ethers from Hardhat package
import { ethers } from "hardhat";

async function main() {
    // Retrieve the contract factory for Tributary
    const Tributary = await ethers.getContractFactory("Tributary");

    // Deploy Tributary
    const tributary = await Tributary.deploy();
    await tributary.deployed(); // Ensure the contract is deployed

    console.log("Tributary deployed to:", tributary.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
