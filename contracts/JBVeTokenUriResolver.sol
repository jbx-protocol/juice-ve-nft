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
>>>>>>> c39af014e83f8f3af63d6b6cf7375ba17c3895a1
    } else {
      return 61;
    }
  }

  /**
     @notice 
     Returns the token duration multiplier needed to index into the righteous veBanny mediallion background.

     @param _duration Time in seconds corresponding with one of five acceptable staking durations. 
     The Staking durations below were gleaned from the JBveBanny.sol contract line 55-59.
     Returns the duration multiplier used to index into the proper veBanny mediallion on IPFS.
  */
<<<<<<< HEAD
  function _getTokenStakeMultiplier(uint256 _duration, uint256[] memory _lockDurationOptions)
    private
    pure
    returns (uint256)
  {
    for (uint256 _i = 0; _i < _lockDurationOptions.length; _i++)
      if (_lockDurationOptions[_i] == _duration) return _i + 1;
    revert JBErrors.INVALID_LOCK_DURATION();
=======
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
    // Convert the token amount and duration to indexes
    uint256 _tokenRange = getTokenRange(_amount);
    uint256 _stakeDuration = getTokenDuration(_duration);
    /*
      To account for multiplicative identity and since we don't have zero as an index we 
      can do the following magic to insure proper Banny character assignment.
    */
    return
      string(
        abi.encodePacked(
          'ipfs://QmWSL7jMuEkkk9798eWVMY9WYurAPRfPDVkHF1e7wJqzdX/',
          Strings.toString(_tokenRange * 5 - 5 + _stakeDuration)
        )
      );
>>>>>>> c39af014e83f8f3af63d6b6cf7375ba17c3895a1
  }
}
