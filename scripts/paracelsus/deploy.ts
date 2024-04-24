// Import ethers from Hardhat package
import { ethers } from "hardhat";

async function main() {
    // Constructor addresses for Paracelsus
    // 0x45d490a39FeD2FaCDbcc95E3D85DAA2f53BB7Bea // Paracelsus Sepolia
    // 0x03228D9E9c9E6E28bE94F1C452d93Fa4260861BB // Undine TEST(ICLES) Sepolia 
    // const univ2RouterAddress = "0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24"; // BASE Mainnet
    const univ2RouterAddress = "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008"; // Sepolia
    const archivistAddress = "0x3194BC21a58Ee5415562C9b07FcC88D3217e8A9b"; // Archivist Sepolia
    const manaPoolAddress = "0x2BC95628E7554B37f856F3e4a78D7D80CAfD94F8"; // ManaPool Sepolia
    const tributaryAddress = "0x6dE70FE9635B0fFd7ef75870EBe1B1Ce152751a8"; // Tributary Sepolia

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
    