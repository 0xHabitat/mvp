import { task, HardhatUserConfig } from 'hardhat/config';
import '@nomiclabs/hardhat-waffle';
import dotenv from 'dotenv';

// This adds support for typescript paths mappings
import 'tsconfig-paths/register';

require('hardhat-gemcutter');

dotenv.config()
const { ALCHEMY_TOKEN } = process.env;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
const goerli = 'https://eth-goerli.g.alchemy.com/v2/';
const optimism = 'https://opt-mainnet.g.alchemy.com/v2/';
const config = {
  defaultNetwork: 'localhost',
  networks: {
    localhost: {
      url: 'http://localhost:8545',
    },
    hardhat: {
      forking: {
        url: optimism + ALCHEMY_TOKEN,
      },
      timeout: 100000,
    },
  },
  solidity: '0.8.9',
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  HardhatUserConfig: {},
};

export default config;
