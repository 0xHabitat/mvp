require("dotenv").config();
import '@nomiclabs/hardhat-waffle';
import 'hardhat-abi-exporter';
require('hardhat-gemcutter');

// This adds support for typescript paths mappings
import 'tsconfig-paths/register';

const hardhatSettings = {
  solidity: "0.8.9",
  defaultNetwork: "localhost",
  networks: {
    localhost: {
      url: "http://localhost:8545",
    },
    hardhat: {
      forking: {
        url: process.env.ALCHEMY_OPTIMISM_MAINNET_URL,
        blockNumber: 14390000
      }
    },
  },
  // abiExporter: {
  //   path: '../metadata',
  //   runOnCompile: true,
  //   clear: true,
  //   flat: true,
  //   only: [
  //     'StakeContractERC20UniV3',
  //     'MockERC20',
  //     'MockVotingPowerHolder',
  //     'PositionValueTest'
  //   ],
  //   spacing: 2,
  //   pretty: false,
  // },
};

export default hardhatSettings