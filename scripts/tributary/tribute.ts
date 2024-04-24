import { ethers } from "hardhat";

async function main() {
    // Hardcoded values for amount and addresses
    const amountInEther = "0.02"; // The amount of Ether you want to contribute.
    const tributaryAddress = "0x6dE70FE9635B0fFd7ef75870EBe1B1Ce152751a8"; // Tributary Sepolia

    const [deployer] = await ethers.getSigners();
    console.log("Using account:", deployer.address);

    // Get the deployed Tributary contract at the specified address with the deployer as the signer
    const Tributary = await ethers.getContractAt("Tributary", tributaryAddress, deployer);

    // Convert amount in Ether to Wei
    const amountInWei = ethers.utils.parseEther(amountInEther);

    // Create a tribute transaction by sending Ether
    const txResponse = await Tributary.tribute(amountInWei, {
        value: amountInWei // Send this much Ether along with the transaction
    });

    console.log("Transaction submitted! Hash:", txResponse.hash);
    const receipt = await txResponse.wait(); // Wait for the transaction to be mined
    console.log("Transaction confirmed! Block number:", receipt.blockNumber);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
