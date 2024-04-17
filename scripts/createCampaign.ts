import { ethers } from "hardhat";

async function main() {
  const tokenName = "MyToken";  // Hardcoded value for token name
  const tokenSymbol = "MTK";    // Hardcoded value for token symbol

  const contractAddress = "Your_Deployed_Contract_Address_Here";
  const [deployer] = await ethers.getSigners();

  const Paracelsus = await ethers.getContractAt("Paracelsus", contractAddress, deployer);
  const txResponse = await Paracelsus.createCampaign(tokenName, tokenSymbol, {
    value: ethers.utils.parseEther("0.01")
  });

  console.log("Transaction submitted! Hash:", txResponse.hash);
  const receipt = await txResponse.wait();
  console.log("Transaction confirmed! Block number:", receipt.blockNumber);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
