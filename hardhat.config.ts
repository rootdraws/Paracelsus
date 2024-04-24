import { HardhatUserConfig } from "hardhat/config";
import '@nomiclabs/hardhat-ethers';
import '@nomicfoundation/hardhat-verify';
import dotenv from "dotenv";

dotenv.config();

const { OP_RPC, SEPOLIA_RPC, ETHERSCAN_API_KEY } = process.env;

// Create an array for the deployer and test accounts with the `0x` prefix
const privateKeys = [
  process.env.PRIVATE_KEY ? `0x${process.env.PRIVATE_KEY}` : undefined, // Deployer's private key
  ...Array.from({ length: 10 }) // Array for up to 10 test accounts
    .map((_, index) => process.env[`PRIVATE_KEY_${index + 1}`] ? `0x${process.env[`PRIVATE_KEY_${index + 1}`]}` : undefined)
    .filter(Boolean) // Filter out any undefined entries
].filter(Boolean) as string[];

const config: HardhatUserConfig = {
  networks: {
    optimism: {
      url: OP_RPC,
      chainId: 10,
      accounts: privateKeys,
    },
    sepolia: {
      url: SEPOLIA_RPC,
      chainId: 11155111,
      accounts: privateKeys,
    }
  },
  solidity: "0.8.25",
  etherscan: {
    apiKey: {
      optimism: ETHERSCAN_API_KEY!,  // You might need different API keys for each network
      sepolia: ETHERSCAN_API_KEY!
    }
  }
};

export default config;
