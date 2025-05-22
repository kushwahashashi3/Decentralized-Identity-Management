require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    // Core Testnet 2 Configuration
    core_testnet2: {
      url: "https://rpc.test2.btcs.network",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1115, // Core Testnet 2 Chain ID
      gasPrice: 20000000000, // 20 gwei
      gas: 8000000,
      timeout: 60000,
    },
    // Local Hardhat Network
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
    // Hardhat Default Network
    hardhat: {
      chainId: 31337,
      accounts: {
        count: 10,
        initialBalance: "1000000000000000000000", // 1000 ETH
      },
    },
  },
  etherscan: {
    apiKey: {
      // Add API key for contract verification if needed
      core_testnet2: process.env.ETHERSCAN_API_KEY || "",
    },
    customChains: [
      {
        network: "core_testnet2",
        chainId: 1115,
        urls: {
          apiURL: "https://api.test2.btcs.network/api",
          browserURL: "https://scan.test2.btcs.network",
        },
      },
    ],
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 40000,
  },
};
