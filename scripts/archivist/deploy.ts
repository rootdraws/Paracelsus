import { ethers } from "hardhat";

async function main() {
    // Retrieve the contract factory for Archivist
    const Archivist = await ethers.getContractFactory("Archivist");

    // Deploy the Archivist contract
    const archivist = await Archivist.deploy();
    await archivist.deployed(); // Ensure the contract is deployed

    console.log("Archivist deployed to:", archivist.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
