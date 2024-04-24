import { ethers } from "hardhat";
import { Event } from "ethers";

async function main() {
  const tokenName = "TEST";  // Hardcoded value for token name
  const tokenSymbol = "ICLES";  // Hardcoded value for token symbol

  // Replace with the actual deployed address
  const contractAddress = "0x45d490a39FeD2FaCDbcc95E3D85DAA2f53BB7Bea"; // Paracelsus Sepolia
  const [deployer] = await ethers.getSigners();

  // Retrieve the contract at the specified address with the deployer as the signer
  const Paracelsus = await ethers.getContractAt("Paracelsus", contractAddress, deployer);

  // Create a new campaign
  const txResponse = await Paracelsus.createCampaign(tokenName, tokenSymbol);
  console.log("Transaction submitted! Hash:", txResponse.hash);

  const receipt = await txResponse.wait(); // Wait for the transaction to be mined

  // Extract the Undine contract address from the event logs
  const undineDeployedEvent = receipt.events?.find((event: Event) => event.event === 'UndineDeployed');
  const undineAddress = undineDeployedEvent?.args?.undineAddress;

  console.log("Transaction confirmed! Block number:", receipt.blockNumber);
  console.log("Undine Contract Address:", undineAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
