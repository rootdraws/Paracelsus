import { ethers } from "hardhat";

async function main() {
    // CONSTRUCTOR ADDRESSES
    // const univ2RouterAddress = "0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24"; // BASE Mainnet
    // const univ2RouterAddress = "0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24"; // OP Sepolia
    const archivistAddress = "0x..."; // Previously deployed Archivist address
    const manaPoolAddress = "0x..."; // Previously deployed ManaPool address
    const salamanderAddress = "0x..."; // Previously deployed Salamander address

    // Retrieve the contract factory for Paracelsus
    const Paracelsus = await ethers.getContractFactory("Paracelsus");

    // Deploy Paracelsus with the necessary contract addresses
    const paracelsus = await Paracelsus.deploy(
        univ2RouterAddress,
        archivistAddress,
        manaPoolAddress,
        salamanderAddress
    );

    console.log("Paracelsus deployed to:", paracelsus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
