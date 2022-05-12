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
  const [deployer] = await ethers.getSigners();

  let multisigAddress, tokenStore, operatorStore;
  let baseDeployArgs = {
    from: deployer.address,
    log: true,
    skipIfAlreadyDeployed: true,
  };

  console.log({ deployer, k: await getChainId() });
  switch (await getChainId()) {
    // mainnet
    case '1':
      tokenStore = '0x9c54a10a35bF8cC8bF4AE52198c782c5681c9470';
      operatorStore = '0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb';
      multisigAddress = '0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e';
      break;
    // rinkeby
    case '4':
      tokenStore = '0xa2C08C071514c46671d675553453755bEf8E95bB';
      operatorStore = '0xEDB2db4b82A4D4956C3B4aA474F7ddf3Ac73c5AB';
      multisigAddress = '0x69C6026e3938adE9e1ddE8Ff6A37eC96595bF1e1';
      break;
    // hardhat / localhost
    case '31337':
      multisigAddress = deployer;
      break;
  }

  const uriResolver = await deploy('JBVeTokenUriResolver', baseDeployArgs)

  const veBanny = await deploy('JBveBanny', {
    ...baseDeployArgs,
    args: [
      1, // project id
      'veBanny', // name
      'veJBX',  // symbol
      uriResolver.address,  // uri resolver
      tokenStore,  // token store
      operatorStore,  // operator store

      // Durations (currently placeholders)
      [
        604800,
        2419200,
        7257600,
      ]
    ],
  });

  console.log({ veBanny: veBanny.address, uriResolver: uriResolver.address });

};
