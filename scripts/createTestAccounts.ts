import { ethers } from "hardhat";

async function main() {
  const accounts = Array.from({length: 10}, () => ethers.Wallet.createRandom());

  console.log("Generated Accounts:");
  accounts.forEach((account, index) => {
    console.log(`Account ${index + 1} - Address: ${account.address}, Private Key: ${account.privateKey}`);
  });
}

main().catch((error) => {
  console.error("Error:", error);
  process.exit(1);
});
