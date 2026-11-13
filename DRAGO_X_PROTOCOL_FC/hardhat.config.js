require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const {
  SEPOLIA_RPC_URL,
  AMOY_RPC_URL,
  BNB_TESTNET_RPC_URL,
  PRIVATE_KEY,
} = process.env;

const accounts = PRIVATE_KEY ? [PRIVATE_KEY.startsWith("0x") ? PRIVATE_KEY : `0x${PRIVATE_KEY}`] : [];

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: { optimizer: { enabled: true, runs: 200 } },
  },
  networks: {
    hardhat: { chainId: 31337 },
    sepolia: {
      url: SEPOLIA_RPC_URL || "http://127.0.0.1:8545",
      accounts,
      chainId: 11155111,
    },
    amoy: {
      url: AMOY_RPC_URL || "http://127.0.0.1:8545",
      accounts,
      chainId: 80002,
    },
    bnbTestnet: {
      url: BNB_TESTNET_RPC_URL || "http://127.0.0.1:8545",
      accounts,
      chainId: 97,
    },
  },
};
