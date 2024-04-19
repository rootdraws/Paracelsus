import { ethers } from "hardhat";

async function main() {
  const tokenName = "TEST";  // Hardcoded value for token name
  const tokenSymbol = "ICLES";    // Hardcoded value for token symbol

  // You need to replace this with the actual address after deployment
  const contractAddress = "Your_Deployed_Contract_Address_Here";
  const [deployer] = await ethers.getSigners();

  // Get the deployed Paracelsus contract at the specified address with the deployer as the signer
  const Paracelsus = await ethers.getContractAt("Paracelsus", contractAddress, deployer);

  // Create a new campaign by sending 0.01 ETH
  const txResponse = await Paracelsus.createCampaign(tokenName, tokenSymbol, {
    value: ethers.utils.parseEther("0.001") // This sends 0.001 ether along with the function call
  });

  console.log("Transaction submitted! Hash:", txResponse.hash);
  const receipt = await txResponse.wait(); // Wait for the transaction to be mined
  console.log("Transaction confirmed! Block number:", receipt.blockNumber);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
