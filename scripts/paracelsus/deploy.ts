// Import ethers from Hardhat package
import { ethers } from "hardhat";

async function main() {
    // Constructor addresses for Paracelsus
    // const univ2RouterAddress = "0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24"; // BASE Mainnet
    const univ2RouterAddress = "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008"; // Sepolia
    const archivistAddress = "0x198756310d7f4D7BaDF9Df0D8E99d4E04F58619b"; // Archivist Sepolia
    const manaPoolAddress = "0x66634Efd01E5Fa22aF81EaC62b014c37806FC448"; // ManaPool Sepolia
    const tributaryAddress = "0xedc3d174C573Bd3dE0E147d37226FE9397a2D984"; // Tributary Sepolia

    // Retrieve the contract factory for Paracelsus
    const Paracelsus = await ethers.getContractFactory("Paracelsus");

    // Deploy Paracelsus with the necessary contract addresses and specific gas limit
    const paracelsus = await Paracelsus.deploy(
        univ2RouterAddress,
        archivistAddress,
        manaPoolAddress,
        tributaryAddress,
        {
            gasLimit: 8000000  // Specify a high gas limit as an override
        }
    );

    // Ensure the contract is deployed
    await paracelsus.deployed();

    console.log("Paracelsus deployed to:", paracelsus.address);
}

// Recommended pattern to handle errors in async functions
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
    