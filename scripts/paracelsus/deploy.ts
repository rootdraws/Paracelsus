import { ethers } from "hardhat";

async function main() {
    // CONSTRUCTOR ADDRESSES
    const univ2RouterAddress = "0x1689E7B1F10000AE47eBfE339a4f69dECd19F602"; // Testnet Univ2 Router on Base Sepolia
    const archivistAddress = "0x..."; // Previously deployed Archivist address
    const manaPoolAddress = "0x..."; // Previously deployed ManaPool address
    const salamanderAddress = "0x..."; // Previously deployed Salamander address
    const epochManagerAddress = "0x..."; // Previously deployed EpochManager address

    // Retrieve the contract factory for Paracelsus
    const Paracelsus = await ethers.getContractFactory("Paracelsus");

    // Deploy Paracelsus with the necessary contract addresses
    const paracelsus = await Paracelsus.deploy(
        univ2RouterAddress,
        archivistAddress,
        manaPoolAddress,
        salamanderAddress,
        epochManagerAddress
    );

    console.log("Paracelsus deployed to:", paracelsus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
