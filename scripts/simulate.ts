// import { ethers } from 'hardhat';
// import JBVeTokenUriResolver from '../deployments/rinkeby/JBVeTokenUriResolver.json';
// import { writeFileSync } from 'fs';
// import { resolve } from 'path';

const durations = [864000, 2160000, 8640000, 21600000, 86400000];
const amounts = [
  1, 101, 201, 401, 501, 601, 701, 801, 901, 1001, 2001, 3001, 4001, 5001, 6001, 7001, 8001, 9001,
  10001, 12001, 14001, 16001, 18001, 20001, 22001, 24001, 26001, 28001, 30001, 40001, 50001, 60001,
  70001, 80001, 90001, 100001, 200001, 300001, 400001, 500001, 600001, 700001, 800001, 900001,
  1000001, 2000001, 3000001, 4000001, 5000001, 6000001, 7000001, 8000001, 9000001, 10000001,
  20000001, 40000001, 50000001, 100000001, 500000001, 700000001,
];

async function simulate(): Promise<void> {
  let str = '';
  for (const amount of amounts) {
    for (const duration of durations) {
      str += `[${amount}|${duration}] => ${tokenURI(amount, duration)}\n`;
    }
    str += '\n';
  }
  console.log(str);
}

simulate();

function getTokenRange(_amount: number) {
  if (_amount <= 0) {
    throw Error('INSUFFICIENT_BALANCE');
  }
  let tokenRange = 0;
  if (_amount >= 1 && _amount <= 100) {
    tokenRange = 1;
  } else if (_amount >= 101 && _amount <= 200) {
    tokenRange = 2;
  } else if (_amount >= 201 && _amount <= 300) {
    tokenRange = 3;
  } else if (_amount >= 301 && _amount <= 400) {
    tokenRange = 4;
  } else if (_amount >= 401 && _amount <= 500) {
    tokenRange = 5;
  } else if (_amount >= 501 && _amount <= 600) {
    tokenRange = 6;
  } else if (_amount >= 601 && _amount <= 700) {
    tokenRange = 7;
  } else if (_amount >= 701 && _amount <= 800) {
    tokenRange = 8;
  } else if (_amount >= 801 && _amount <= 900) {
    tokenRange = 9;
  } else if (_amount >= 901 && _amount <= 1_000) {
    tokenRange = 10;
  } else if (_amount >= 1_001 && _amount <= 2_000) {
    tokenRange = 11;
  } else if (_amount >= 2_001 && _amount <= 3_000) {
    tokenRange = 12;
  } else if (_amount >= 3_001 && _amount <= 4_000) {
    tokenRange = 13;
  } else if (_amount >= 4_001 && _amount <= 5_000) {
    tokenRange = 14;
  } else if (_amount >= 5_001 && _amount <= 6_000) {
    tokenRange = 15;
  } else if (_amount >= 6_001 && _amount <= 7_000) {
    tokenRange = 16;
  } else if (_amount >= 7_001 && _amount <= 8_000) {
    tokenRange = 17;
  } else if (_amount >= 8_001 && _amount <= 9_000) {
    tokenRange = 18;
  } else if (_amount >= 9_001 && _amount <= 10_000) {
    tokenRange = 19;
  } else if (_amount >= 10_001 && _amount <= 12_000) {
    tokenRange = 20;
  } else if (_amount >= 12_001 && _amount <= 14_000) {
    tokenRange = 21;
  } else if (_amount >= 14_001 && _amount <= 16_000) {
    tokenRange = 22;
  } else if (_amount >= 16_001 && _amount <= 18_000) {
    tokenRange = 23;
  } else if (_amount >= 18_001 && _amount <= 20_000) {
    tokenRange = 24;
  } else if (_amount >= 20_001 && _amount <= 22_000) {
    tokenRange = 25;
  } else if (_amount >= 22_001 && _amount <= 24_000) {
    tokenRange = 26;
  } else if (_amount >= 24_001 && _amount <= 26_000) {
    tokenRange = 27;
  } else if (_amount >= 26_001 && _amount <= 28_000) {
    tokenRange = 28;
  } else if (_amount >= 28_001 && _amount <= 30_000) {
    tokenRange = 29;
  } else if (_amount >= 30_001 && _amount <= 40_000) {
    tokenRange = 30;
  } else if (_amount >= 40_001 && _amount <= 50_000) {
    tokenRange = 31;
  } else if (_amount >= 50_001 && _amount <= 60_000) {
    tokenRange = 32;
  } else if (_amount >= 60_001 && _amount <= 70_000) {
    tokenRange = 33;
  } else if (_amount >= 70_001 && _amount <= 80_000) {
    tokenRange = 34;
  } else if (_amount >= 80_001 && _amount <= 90_000) {
    tokenRange = 35;
  } else if (_amount >= 90_001 && _amount <= 100_000) {
    tokenRange = 36;
  } else if (_amount >= 100_001 && _amount <= 200_000) {
    tokenRange = 37;
  } else if (_amount >= 200_001 && _amount <= 300_000) {
    tokenRange = 38;
  } else if (_amount >= 300_001 && _amount <= 400_000) {
    tokenRange = 39;
  } else if (_amount >= 400_001 && _amount <= 500_000) {
    tokenRange = 40;
  } else if (_amount >= 500_001 && _amount <= 600_000) {
    tokenRange = 41;
  } else if (_amount >= 600_001 && _amount <= 700_000) {
    tokenRange = 42;
  } else if (_amount >= 700_001 && _amount <= 800_000) {
    tokenRange = 43;
  } else if (_amount >= 800_001 && _amount <= 900_000) {
    tokenRange = 44;
  } else if (_amount >= 900_001 && _amount <= 1_000_000) {
    tokenRange = 45;
  } else if (_amount >= 1_000_001 && _amount <= 2_000_000) {
    tokenRange = 46;
  } else if (_amount >= 2_000_001 && _amount <= 3_000_000) {
    tokenRange = 47;
  } else if (_amount >= 3_000_001 && _amount <= 4_000_000) {
    tokenRange = 48;
  } else if (_amount >= 4_000_001 && _amount <= 5_000_000) {
    tokenRange = 49;
  } else if (_amount >= 5_000_001 && _amount <= 6_000_000) {
    tokenRange = 50;
  } else if (_amount >= 6_000_001 && _amount <= 7_000_000) {
    tokenRange = 51;
  } else if (_amount >= 7_000_001 && _amount <= 8_000_000) {
    tokenRange = 52;
  } else if (_amount >= 8_000_001 && _amount <= 9_000_000) {
    tokenRange = 53;
  } else if (_amount >= 9_000_001 && _amount <= 10_000_000) {
    tokenRange = 54;
  } else if (_amount >= 10_000_001 && _amount <= 20_000_000) {
    tokenRange = 55;
  } else if (_amount >= 20000001 && _amount <= 40000000) {
    tokenRange = 56;
  } else if (_amount >= 40_000_001 && _amount <= 60_000_000) {
    tokenRange = 57;
  } else if (_amount >= 60_000_001 && _amount <= 100_000_000) {
    tokenRange = 58;
  } else if (_amount >= 100_000_001 && _amount <= 600_000_000) {
    tokenRange = 59;
  } else if (_amount >= 600_000_001) {
    tokenRange = 60;
  } else {
    throw Error('INSUFFICIENT_BALANCE');
  }
  return tokenRange;
}

/**
     @notice Returns the token duration multiplier needed to index into the righteous veBanny mediallion background.
     @param _duration Time in seconds corresponding with one of five acceptable staking durations. 
     The Staking durations below were gleaned from the JBveBanny.sol contract line 55-59.
     Returns the duration multiplier used to index into the proper veBanny mediallion on IPFS.
  */
function getTokenDuration(_duration: number) {
  if (_duration <= 0) {
    throw Error('INVALID DURATION');
  }
  let _stakeMultiplier = 0;
  if (durations[0] == _duration) {
    _stakeMultiplier = 1;
  } else if (durations[1] == _duration) {
    _stakeMultiplier = 2;
  } else if (durations[2] == _duration) {
    _stakeMultiplier = 3;
  } else if (durations[3] == _duration) {
    _stakeMultiplier = 4;
  } else if (durations[4] == _duration) {
    _stakeMultiplier = 5;
  } else {
    throw Error('INVALID_DURATION');
  }
  return _stakeMultiplier;
}

/**
     @notice Computes the specific veBanny IPFS URI  based on the above locked Juicebox token range index and the duration multiplier.
     @param _amount Amount of locked Juicebox. 
     @param _duration Duration in seconds to stake Juicebox.
     Returns one of the epic and totally righteous veBanny character IPFS URI the user is entitled to with the aforementioned parameters.
    */
function tokenURI(_amount: number, _duration: number) {
  if (_amount <= 0) {
    throw Error('INSUFFICIENT_BALANCE');
  }
  if (_duration <= 0) {
    throw Error('INVALID_DURATION');
  }
  let _tokenRange = getTokenRange(_amount);
  let _stakeMultiplier = getTokenDuration(_duration);
  return `ipfs://QmauKpZU5NyDWJBkcFZGLCcbXLXZV4z86k2Mhi3sPHvuUZ/${
    _tokenRange * 5 - 5 + _stakeMultiplier
  }`;
}
