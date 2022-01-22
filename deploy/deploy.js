const { ethers } = require('hardhat');

/**
 * Deploys the JBX STaking Contracts.
 *
 * Example usage:
 *
 * npx hardhat deploy --network rinkeby
 *
 */
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  let multisigAddress;

  console.log({ deployer, k: await getChainId() });
  switch (await getChainId()) {
    // mainnet
    case '1':
      multisigAddress = '0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e';
      break;
    // rinkeby
    case '4':
      multisigAddress = '0x69C6026e3938adE9e1ddE8Ff6A37eC96595bF1e1';
      break;
    // hardhat / localhost
    case '31337':
      multisigAddress = deployer;
      break;
  }

  console.log({ multisigAddress });

};
