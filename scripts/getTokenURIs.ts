import { ethers, network } from 'hardhat';

const _durations = [864000, 2160000, 8640000, 21600000, 86400000];
const _amounts = [
  1, 101, 201, 401, 501, 601, 701, 801, 901, 1001, 2001, 3001, 4001, 5001, 6001, 7001, 8001, 9001,
  10001, 12001, 14001, 16001, 18001, 20001, 22001, 24001, 26001, 28001, 30001, 40001, 50001, 60001,
  70001, 80001, 90001, 100001, 200001, 300001, 400001, 500001, 600001, 700001, 800001, 900001,
  1000001, 2000001, 3000001, 4000001, 5000001, 6000001, 7000001, 8000001, 9000001, 10000001,
  20000001, 40000001, 50000001, 100000001, 500000001, 700000001,
];

async function printTokenURIs() {
  const JBVeTokenUriResolver = require(`../deployments/${network.name}/JBVeTokenUriResolver.json`);
  const [signer] = await ethers.getSigners();
  const contract = new ethers.Contract(
    JBVeTokenUriResolver.address,
    JBVeTokenUriResolver.abi,
    signer,
  );
  for (const amount of _amounts) {
    for (const duration of _durations) {
      console.log(
        `tokenURI(${amount},${duration}) => ${await contract.tokenURI(amount, duration)}`,
      );
    }
    console.log();
  }
}

printTokenURIs();
