import "@nomiclabs/hardhat-ethers";
import { HardhatUserConfig } from "hardhat/config";
import dotenv from "dotenv";

dotenv.config(); // This loads the environment variables from the .env file

const { PRIVATE_KEY, RPC_URL } = process.env; // Destructure the environment variables

const config: HardhatUserConfig = {
  networks: {
    mode: {
      url: "https://sepolia.mode.network",
      chainId: 919,
      accounts: PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : [], // Use the private key from the environment variable
    }
  },
  solidity: "0.8.25",
};

export default config;
