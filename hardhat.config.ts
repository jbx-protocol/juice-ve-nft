import dotenv from 'dotenv';
import { task } from 'hardhat/config';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import 'hardhat-gas-reporter';
import 'hardhat-deploy';

dotenv.config();

const chainIds = {
  mainnet: 1,
  ropsten: 3,
  rinkeby: 4,
  goerli: 5,
  kovan: 42,
  polygon: 137,
  ganache: 1337,
  hardhat: 31337,
  mumbai: 80001,
};

const defaultNetwork = 'localhost';

const VERBOSE = false;

const INFURA_API_KEY = process.env.INFURA_API_KEY;
const ALCHEMY_MUMBAI_API_KEY = process.env.ALCHEMY_MUMBAI_API_KEY;
const ALCHEMY_MATIC_API_KEY = process.env.ALCHEMY_MATIC_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

task('accounts', 'Prints the list of available ETH accounts:', async (args, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(await account.address);
  }
});

task('networks', 'Prints the configured ETH network settings:', async (args, hre) => {
  if (VERBOSE) {
    console.log(`Available Networks:`);
    console.log(hre['config']['networks']);
  } else {
    Object.keys(chainIds).forEach((k) => {
      console.log(`Network ${k}`);
      console.log(hre['config']['networks'][`${k}`]);
    });
  }
});

export default {
  defaultNetwork,
  networks: {
    localhost: {
      url: 'http://localhost:8545',
      blockGasLimit: 0x1fffffffffffff,
    },
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/' + INFURA_API_KEY,
      gasPrice: 50000000000,
      accounts: [PRIVATE_KEY],
    },
    mainnet: {
      url: 'https://mainnet.infura.io/v3/' + INFURA_API_KEY,
      gasPrice: 50000000000,
      accounts: [PRIVATE_KEY],
    },
    mumbai: {
      allowUnlimitedContractSize: true,
      url: 'https://polygon-mumbai.g.alchemy.com/v2/' + ALCHEMY_MUMBAI_API_KEY,
      accounts: [PRIVATE_KEY],
    },
    matic: {
      allowUnlimitedContractSize: true,
      url: 'https://polygon-mainnet.g.alchemy.com/v2/' + ALCHEMY_MATIC_API_KEY,
      accounts: [PRIVATE_KEY],
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    feeCollector: {
      default: 0,
    },
  },
  solidity: {
    compilers: [
      {
        version: '0.8.6',
        settings: {
          metadata: {
            /* Not including the metadata hash
            https://github.com/paulrberg/solidity-template/issues/31 */
            bytecodeHash: 'none',
          },
          /* You should disable the optimizer when debugging
          https://hardhat.org/hardhat-network/#solidity-optimizer-support */
          optimizer: {
            enabled: true,
            runs: 800,
          },
        },
      },
      { version: '0.6.0' },
    ],
  },
  mocha: {
    bail: true,
    timeout: 6000,
  },
  gasReporter: {
    currency: 'USD',
    enabled: !!process.env.REPORT_GAS,
    showTimeSpent: true,
  },
  etherscan: {
    apiKey: `${process.env.ETHERSCAN_API_KEY}`,
  },
  paths: {
    sources: './contracts',
    artifacts: './artifacts',
    cache: './cache',
    tests: './test',
  },
};
