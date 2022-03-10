// import { ethers } from 'hardhat';

/**
 * Deploys the JBX STaking Contracts.
 *
 * Example usage:
 *
 * npx hardhat deploy --network rinkeby
 *
 */
export default async ({ getNamedAccounts, deployments, getChainId }: { [k: string]: Function }) => {
  // const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  let multisigAddress;

  console.log({ deployer, k: await getChainId() });
  switch (await getChainId()) {
    // mainnet
    case '1':
      multisigAddress = '0x23cB4bD6007b75dD34f43F1fE593C167A39f0A29';
      break;
    // rinkeby
    case '4':
      multisigAddress = '0x1d98FdCB503E5013ABF779Cb0fFbE2a30B740AE7';
      break;
    // hardhat / localhost
    case '31337':
      multisigAddress = deployer;
      break;
  }

  console.log({ multisigAddress });
};
