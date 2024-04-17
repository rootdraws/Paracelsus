// Import ethers from Hardhat package
import { ethers } from "hardhat";

async function main() {
    // Retrieve the contract factory for Paracelsus
    const Paracelsus = await ethers.getContractFactory("Paracelsus");

    // Address for the univ2Router - replace with the actual address you're using
    const univ2Router = "0x1689E7B1F10000AE47eBfE339a4f69dECd19F602"; // Testnet Univ2 Router on Base Sepolia

    // Deploy Paracelsus with the univ2 Router address
    const paracelsus = await Paracelsus.deploy(univ2Router);
    console.log("Paracelsus deployed to:", paracelsus.address);

    // If needed, retrieve deployed contract addresses from the Paracelsus contract
    // Assume getters exist in Paracelsus contract for each deployed contract address
    const archivistAddress = await paracelsus.archivist();
    const epochManagerAddress = await paracelsus.epochManager();
    const manaPoolAddress = await paracelsus.manaPool();
    const salamanderAddress = await paracelsus.salamander();

    console.log("Archivist deployed to:", archivistAddress);
    console.log("EpochManager deployed to:", epochManagerAddress);
    console.log("ManaPool deployed to:", manaPoolAddress);
    console.log("Salamander deployed to:", salamanderAddress);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
