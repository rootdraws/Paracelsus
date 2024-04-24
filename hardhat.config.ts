import "@nomiclabs/hardhat-ethers";
import { HardhatUserConfig } from "hardhat/config";
import dotenv from "dotenv";

dotenv.config(); // This loads the environment variables from the .env file

const { PRIVATE_KEY, OP_RPC, SEPOLIA_RPC } = process.env; // Destructure the environment variables

const config: HardhatUserConfig = {
  networks: {
    optimism: {
      url: OP_RPC, // Use the RPC URL from the environment variable
      chainId: 10,
      accounts: PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : [] // Use the private key from the environment variable
    },
  sepolia: {
      url: SEPOLIA_RPC, // Use the RPC URL from the environment variable
      chainId: 11155111,
      accounts: PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : [] // Use the private key from the environment variable
    }
  },
  solidity: "0.8.25",
};

export default config;
