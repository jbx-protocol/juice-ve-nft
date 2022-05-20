import { DeployFunction } from 'hardhat-deploy/dist/types';

/**
 * Deploys the JBX STaking Contracts.
 *
 * Example usage:
 *
 * npx hardhat deploy --network rinkeby
 *
 */
const fn: DeployFunction = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  let multisigAddress;

  console.log({ deployer, k: await getChainId() });
  switch (await getChainId()) {
    // mainnet
    case '1':
      multisigAddress = deployer;
      break;
    // rinkeby
    case '4':
      multisigAddress = deployer;
      break;
    // hardhat / localhost
    case '31337':
      multisigAddress = deployer;
      break;
  }

  console.log({ multisigAddress });

  const JBVeTokenUriResolver = await deploy('JBVeTokenUriResolver', {
    from: deployer,
    args: [],
  });
  console.log({ address: JBVeTokenUriResolver.address });
};

export default fn;
