// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './interfaces/IJBVeTokenUriResolver.sol';
import './libraries/JBErrors.sol';


contract JBVeTokenUriResolver is IJBVeTokenUriResolver {
  using SafeMath for uint256;

  /** 
    @notice 
    Computes the metadata url.

    @param _amount Lock Amount.
    @param _duration Lock time in seconds.
    @param _lockDurationOptions The options that the duration can be.

    @return The metadata url.
  */
  function tokenURI(
    uint256,
    uint256 _amount,
    uint256 _duration,
    uint256,
    uint256[] memory _lockDurationOptions
  ) external pure override returns (string memory) {
    if (_amount <= 0) {
      revert JBErrors.INSUFFICIENT_BALANCE();
    }
    if (_duration <= 0) {
      revert JBErrors.INVALID_LOCK_DURATION();
    }
    uint256 _tokenRange = _getTokenRange(_amount);
    uint256 _stakeMultiplier = _getTokenStakeMultiplier(_duration, _lockDurationOptions);
    return
      string(
        abi.encodePacked(
          'ipfs://QmVicV3vNyPKtKxYPPPiVKxaAFa8X2kP5xys6NFhiHf8zj/',
          Strings.toString(_tokenRange * _stakeMultiplier)
        )
      );
  }

  /**
    @notice 
    Returns the veBanny character index needed to compute the righteous veBanny on IPFS.

    @dev
    The range values referenced below were gleaned from the following Notion URL. 
    https://www.notion.so/juicebox/veBanny-proposal-from-Jango-2-68c6f578bef84205a9f87e3f1057aa37

    @param _amount Amount of locked Juicebox.     

    @return The token range index or veBanny character commensurate with amount of locked Juicebox.
  */
  function _getTokenRange(uint256 _amount) private pure returns (uint256) {
    if (_amount >= 1 && _amount <= 100) {
      return 1;
    } else if (_amount >= 101 && _amount <= 200) {
      return 2;
    } else if (_amount >= 201 && _amount <= 300) {
      return 3;
    } else if (_amount >= 401 && _amount <= 500) {
      return 4;
    } else if (_amount >= 501 && _amount <= 600) {
      return 5;
    } else if (_amount >= 601 && _amount <= 700) {
      return 6;
    } else if (_amount >= 701 && _amount <= 800) {
      return 7;
    } else if (_amount >= 801 && _amount <= 900) {
      return 8;
    } else if (_amount >= 901 && _amount <= 1000) {
      return 9;
    } else if (_amount >= 1001 && _amount <= 2000) {
      return 10;
    } else if (_amount >= 2001 && _amount <= 3000) {
      return 11;
    } else if (_amount >= 3001 && _amount <= 4000) {
      return 12;
    } else if (_amount >= 4001 && _amount <= 5000) {
      return 13;
    } else if (_amount >= 5001 && _amount <= 6000) {
      return 14;
    } else if (_amount >= 6001 && _amount <= 7000) {
      return 15;
    } else if (_amount >= 7001 && _amount <= 8000) {
      return 16;
    } else if (_amount >= 8001 && _amount <= 9000) {
      return 17;
    } else if (_amount >= 9001 && _amount <= 10000) {
      return 18;
    } else if (_amount >= 10001 && _amount <= 12000) {
      return 19;
    } else if (_amount >= 12001 && _amount <= 14000) {
      return 20;
    } else if (_amount >= 14001 && _amount <= 16000) {
      return 21;
    } else if (_amount >= 16001 && _amount <= 18000) {
      return 22;
    } else if (_amount >= 18001 && _amount <= 20000) {
      return 23;
    } else if (_amount >= 20001 && _amount <= 22000) {
      return 24;
    } else if (_amount >= 22001 && _amount <= 24000) {
      return 25;
    } else if (_amount >= 24001 && _amount <= 26000) {
      return 26;
    } else if (_amount >= 26001 && _amount <= 28000) {
      return 27;
    } else if (_amount >= 28001 && _amount <= 30000) {
      return 28;
    } else if (_amount >= 30001 && _amount <= 40000) {
      return 29;
    } else if (_amount >= 40001 && _amount <= 50000) {
      return 30;
    } else if (_amount >= 50001 && _amount <= 60000) {
      return 31;
    } else if (_amount >= 60001 && _amount <= 70000) {
      return 32;
    } else if (_amount >= 70001 && _amount <= 80000) {
      return 33;
    } else if (_amount >= 80001 && _amount <= 90000) {
      return 34;
    } else if (_amount >= 90001 && _amount <= 100000) {
      return 35;
    } else if (_amount >= 100001 && _amount <= 200000) {
      return 36;
    } else if (_amount >= 200001 && _amount <= 300000) {
      return 37;
    } else if (_amount >= 300001 && _amount <= 400000) {
      return 38;
    } else if (_amount >= 400001 && _amount <= 500000) {
      return 39;
    } else if (_amount >= 500001 && _amount <= 600000) {
      return 40;
    } else if (_amount >= 600001 && _amount <= 700000) {
      return 41;
    } else if (_amount >= 700001 && _amount <= 800000) {
      return 42;
    } else if (_amount >= 800001 && _amount <= 900000) {
      return 43;
    } else if (_amount >= 900001 && _amount <= 1000000) {
      return 44;
    } else if (_amount >= 1000001 && _amount <= 2000000) {
      return 45;
    } else if (_amount >= 2000001 && _amount <= 3000000) {
      return 46;
    } else if (_amount >= 3000001 && _amount <= 4000000) {
      return 47;
    } else if (_amount >= 4000001 && _amount <= 5000000) {
      return 48;
    } else if (_amount >= 5000001 && _amount <= 6000000) {
      return 49;
    } else if (_amount >= 6000001 && _amount <= 7000000) {
      return 50;
    } else if (_amount >= 7000001 && _amount <= 8000000) {
      return 51;
    } else if (_amount >= 8000001 && _amount <= 9000000) {
      return 52;
    } else if (_amount >= 9000001 && _amount <= 10000000) {
      return 53;
    } else if (_amount >= 10000001 && _amount <= 20000000) {
      return 54;
    } else if (_amount >= 20000001 && _amount <= 40000000) {
      return 55;
    } else if (_amount >= 40000001 && _amount <= 50000000) {
      return 56;
    } else if (_amount >= 50000001 && _amount <= 100000000) {
      return 57;
    } else if (_amount >= 100000001 && _amount <= 500000000) {
      return 58;
    } else if (_amount >= 500000001 && _amount <= 700000000) {
      return 59;
    } else {
      return 60;
    }
  }

  /**
     @notice 
     Returns the token duration multiplier needed to index into the righteous veBanny mediallion background.

     @param _duration Time in seconds corresponding with one of five acceptable staking durations. 
     The Staking durations below were gleaned from the JBveBanny.sol contract line 55-59.
     Returns the duration multiplier used to index into the proper veBanny mediallion on IPFS.
  */
  function _getTokenStakeMultiplier(uint256 _duration, uint256[] memory _lockDurationOptions)
    private
    pure
    returns (uint256)
  {
    for (uint256 _i = 0; _i < _lockDurationOptions.length; _i++)
      if (_lockDurationOptions[_i] == _duration) return _i + 1;
    revert JBErrors.INVALID_LOCK_DURATION();
  }
}
