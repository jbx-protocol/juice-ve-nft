// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './JBConstants.sol';
import './JBErrors.sol';

/**
  @notice
  Resolves URI for the veBanny according to token ranges and staking duration. 
  @dev   
  IPFS CID is hard-coded as the TokenUriResolver can be updated.  
*/
contract JBVeTokenUriResolver {  
  using SafeMath for uint256;
  /**
    @notice
    Convienent structure to map locked token durations.
  */
  uint256[] private _DURATIONS = [
    uint256(JBConstants.TEN_DAYS),
    uint256(JBConstants.TWENTY_FIVE_DAYS),
    uint256(JBConstants.ONE_HUNDRED_DAYS),
    uint256(JBConstants.TWO_HUNDRED_FIFTY_DAYS),
    uint256(JBConstants.ONE_THOUSAND_DAYS)
  ];

  /**
     @notice Computes the metadata url.
     @param _amount Lock JB token amount.
     @param _duration Lock time in seconds, _DURATIONS are the only valid durations.
     Returns metadata url.
    */
  function tokenURI(uint256 _amount, uint256 _duration) public view returns (string memory uri) {
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
      for (uint256 i = uint256(_DURATIONS.length - 1); i >= 0; i -= 1) {
        if (_DURATIONS[i] == _duration) {            
          return
            string(              
              abi.encodePacked('ipfs://QmZ95SaBa3VWb2X7o9bPniWKYBQ2uCnjBmhSUhLq7orjRS/', Strings.toString(bucket * 5 + i))              
            );
        }
      }
    } else revert INVALID_DURATION();
    revert INSUFFICIENT_BALANCE();
  }
}
