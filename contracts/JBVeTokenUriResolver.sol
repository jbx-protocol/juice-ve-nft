// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './interfaces/IJBVeTokenUriResolver.sol';

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error INVALID_DURATION();
error INSUFFICIENT_BALANCE();

/**
  @notice
  Resolves URI for the veBanny according to token ranges and staking duration. 
  @dev   
  IPFS CID is hard-coded as the TokenUriResolver can be updated.  
*/
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
      revert INSUFFICIENT_BALANCE();
    }
    if (_duration <= 0) {
      revert INVALID_DURATION();
    }

    /**
    @notice
    Compute the URI based on the token amount and duration to arrive which of the 300 possible token mediallion is awarded.
    Buckets were defined https://www.notion.so/veBanny-proposal-from-Jango-2-68c6f578bef84205a9f87e3f1057aa37
    */
    uint256 bucket = 59;
    while (bucket >= 0) {
      uint256 maxAmount = uint256(bucket + 1) * 1000 + uint256(14**bucket).div(10**bucket);
      if (_amount >= maxAmount) {
        bucket += 1;
        break;
      } else if (bucket == 0) break;
      bucket -= 1;
    }
    if (bucket < 60) {
      for (uint256 i = uint256(_lockDurationOptions.length - 1); i >= 0; i -= 1) {
        if (_lockDurationOptions[i] == _duration) {
          return
            string(
              abi.encodePacked(
                'ipfs://QmZ95SaBa3VWb2X7o9bPniWKYBQ2uCnjBmhSUhLq7orjRS/',
                Strings.toString(bucket * 5 + i)
              )
            );
        }
      }
    } else revert INVALID_DURATION();
    revert INSUFFICIENT_BALANCE();
  }
}
