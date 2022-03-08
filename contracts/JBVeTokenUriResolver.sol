// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './JBConstants.sol';
import './JBErrors.sol';

contract JBVeTokenUriResolver {
  using SafeMath for uint256;

  /**
     @notice Returns the veBanny character index needed to compute the righteous veBanny on IPFS.
     @param _amount Amount of locked Juicebox.     
     The range values referenced below were gleaned from the following Notion URL. 
     https://www.notion.so/juicebox/veBanny-proposal-from-Jango-2-68c6f578bef84205a9f87e3f1057aa37
     Returns the token range index or veBanny character commensurate with amount of locked Juicebox.
  */
  function getTokenRange(uint256 _amount) public pure returns (uint256) {
    if (_amount <= 0) {
      revert INSUFFICIENT_BALANCE();
    }
    uint256 tokenRange = 0;
    if (_amount >= 1 && _amount <= 100) {
      tokenRange = 1;
    } else if (_amount >= 101 && _amount <= 200) {
      tokenRange = 2;
    } else if (_amount >= 201 && _amount <= 300) {
      tokenRange = 3;
    } else if (_amount >= 401 && _amount <= 500) {
      tokenRange = 4;
    } else if (_amount >= 501 && _amount <= 600) {
      tokenRange = 5;
    } else if (_amount >= 601 && _amount <= 700) {
      tokenRange = 6;
    } else if (_amount >= 701 && _amount <= 800) {
      tokenRange = 7;
    } else if (_amount >= 801 && _amount <= 900) {
      tokenRange = 8;
    } else if (_amount >= 901 && _amount <= 1000) {
      tokenRange = 9;
    } else if (_amount >= 1001 && _amount <= 2000) {
      tokenRange = 10;
    } else if (_amount >= 2001 && _amount <= 3000) {
      tokenRange = 11;
    } else if (_amount >= 3001 && _amount <= 4000) {
      tokenRange = 12;
    } else if (_amount >= 4001 && _amount <= 5000) {
      tokenRange = 13;
    } else if (_amount >= 5001 && _amount <= 6000) {
      tokenRange = 14;
    } else if (_amount >= 6001 && _amount <= 7000) {
      tokenRange = 15;
    } else if (_amount >= 7001 && _amount <= 8000) {
      tokenRange = 16;
    } else if (_amount >= 8001 && _amount <= 9000) {
      tokenRange = 17;
    } else if (_amount >= 9001 && _amount <= 10000) {
      tokenRange = 18;
    } else if (_amount >= 10001 && _amount <= 12000) {
      tokenRange = 19;
    } else if (_amount >= 12001 && _amount <= 14000) {
      tokenRange = 20;
    } else if (_amount >= 14001 && _amount <= 16000) {
      tokenRange = 21;
    } else if (_amount >= 16001 && _amount <= 18000) {
      tokenRange = 22;
    } else if (_amount >= 18001 && _amount <= 20000) {
      tokenRange = 23;
    } else if (_amount >= 20001 && _amount <= 22000) {
      tokenRange = 24;
    } else if (_amount >= 22001 && _amount <= 24000) {
      tokenRange = 25;
    } else if (_amount >= 24001 && _amount <= 26000) {
      tokenRange = 26;
    } else if (_amount >= 26001 && _amount <= 28000) {
      tokenRange = 27;
    } else if (_amount >= 28001 && _amount <= 30000) {
      tokenRange = 28;
    } else if (_amount >= 30001 && _amount <= 40000) {
      tokenRange = 29;
    } else if (_amount >= 40001 && _amount <= 50000) {
      tokenRange = 30;
    } else if (_amount >= 50001 && _amount <= 60000) {
      tokenRange = 31;
    } else if (_amount >= 60001 && _amount <= 70000) {
      tokenRange = 32;
    } else if (_amount >= 70001 && _amount <= 80000) {
      tokenRange = 33;
    } else if (_amount >= 80001 && _amount <= 90000) {
      tokenRange = 34;
    } else if (_amount >= 90001 && _amount <= 100000) {
      tokenRange = 35;
    } else if (_amount >= 100001 && _amount <= 200000) {
      tokenRange = 36;
    } else if (_amount >= 200001 && _amount <= 300000) {
      tokenRange = 37;
    } else if (_amount >= 300001 && _amount <= 400000) {
      tokenRange = 38;
    } else if (_amount >= 400001 && _amount <= 500000) {
      tokenRange = 39;
    } else if (_amount >= 500001 && _amount <= 600000) {
      tokenRange = 40;
    } else if (_amount >= 600001 && _amount <= 700000) {
      tokenRange = 41;
    } else if (_amount >= 700001 && _amount <= 800000) {
      tokenRange = 42;
    } else if (_amount >= 800001 && _amount <= 900000) {
      tokenRange = 43;
    } else if (_amount >= 900001 && _amount <= 1000000) {
      tokenRange = 44;
    } else if (_amount >= 1000001 && _amount <= 2000000) {
      tokenRange = 45;
    } else if (_amount >= 2000001 && _amount <= 3000000) {
      tokenRange = 46;
    } else if (_amount >= 3000001 && _amount <= 4000000) {
      tokenRange = 47;
    } else if (_amount >= 4000001 && _amount <= 5000000) {
      tokenRange = 48;
    } else if (_amount >= 5000001 && _amount <= 6000000) {
      tokenRange = 49;
    } else if (_amount >= 6000001 && _amount <= 7000000) {
      tokenRange = 50;
    } else if (_amount >= 7000001 && _amount <= 8000000) {
      tokenRange = 51;
    } else if (_amount >= 8000001 && _amount <= 9000000) {
      tokenRange = 52;
    } else if (_amount >= 9000001 && _amount <= 10000000) {
      tokenRange = 53;
    } else if (_amount >= 10000001 && _amount <= 20000000) {
      tokenRange = 54;
    } else if (_amount >= 20000001 && _amount <= 40000000) {
      tokenRange = 55;
    } else if (_amount >= 40000001 && _amount <= 50000000) {
      tokenRange = 56;
    } else if (_amount >= 50000001 && _amount <= 100000000) {
      tokenRange = 57;
    } else if (_amount >= 100000001 && _amount <= 500000000) {
      tokenRange = 58;
    } else if (_amount >= 500000001 && _amount <= 700000000) {
      tokenRange = 59;
    } else if (_amount >= 700000001) {
      tokenRange = 60;
    } else {
      revert INSUFFICIENT_BALANCE();
    }
    return tokenRange;
  }

  /**
     @notice Returns the token duration multiplier needed to index into the righteous veBanny mediallion background.
     @param _duration Time in seconds corresponding with one of five acceptable staking durations. 
     The Staking durations below were gleaned from the JBveBanny.sol contract line 55-59.
     Returns the duration multiplier used to index into the proper veBanny mediallion on IPFS.
  */
  function getTokenDuration(uint256 _duration) public pure returns (uint256) {
    if (_duration <= 0) {
      revert INVALID_DURATION();
    }
    uint16 _stakeMultiplier = 0;
    if (uint256(JBConstants.TEN_DAYS) == _duration) {
      _stakeMultiplier = 1;
    } else if (uint256(JBConstants.TWENTY_FIVE_DAYS) == _duration) {
      _stakeMultiplier = 2;
    } else if (uint256(JBConstants.ONE_HUNDRED_DAYS) == _duration) {
      _stakeMultiplier = 3;
    } else if (uint256(JBConstants.TWO_HUNDRED_FIFTY_DAYS) == _duration) {
      _stakeMultiplier = 4;
    } else if (uint256(JBConstants.ONE_THOUSAND_DAYS) == _duration) {
      _stakeMultiplier = 5;
    } else {
      revert INVALID_DURATION();
    }
    return _stakeMultiplier;
  }

  /**
     @notice Computes the specific veBanny IPFS URI  based on the above locked Juicebox token range index and the duration multiplier.
     @param _amount Amount of locked Juicebox. 
     @param _duration Duration in seconds to stake Juicebox.
     Returns one of the epic and totally righteous veBanny character IPFS URI the user is entitled to with the aforementioned parameters.
    */
  function tokenURI(uint256 _amount, uint256 _duration) public pure returns (string memory uri) {
    if (_amount <= 0) {
      revert INSUFFICIENT_BALANCE();
    }
    if (_duration <= 0) {
      revert INVALID_DURATION();
    }
    uint256 _tokenRange = getTokenRange(_amount);
    uint256 _stakeMultiplier = getTokenDuration(_duration);
    return string(abi.encodePacked('ipfs://QmVicV3vNyPKtKxYPPPiVKxaAFa8X2kP5xys6NFhiHf8zj/', Strings.toString(_tokenRange * _stakeMultiplier)));
  }
}
