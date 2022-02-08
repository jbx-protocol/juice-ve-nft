// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol'; 

error INVALID_ACCOUNT();
error INSUFFICIENT_BALANCE();
error INSUFFICIENT_ALLOWANCE();
error LOCK_PERIOD_NOT_OVER();

/**
  @notice
  Allows JBX Holders to stake their tokens and receive Jbx Banny based ont heir stake and lock in period.
  @dev 
  Bannies are transferrable, will be burnt when the stake is claimed before or after the lock-in period ends.
  The Token URI will be determined by SVG for each banny category.
  Inherits from:
  ERC1155 - for ERC1155 support.
  ERC1155Burnable - for burning the bannies.
*/
contract JBveBanny is ERC721Votes, Ownable, ReentrancyGuard {
  /** 
    @notice 
    JBX Token Instance
    */
  IERC20 public immutable jbx;

  mapping(uint256 => uint256) private _packedSpecs;

  uint256 public count;

  event Lock(address account, uint256 amount, uint48 duration, address beneficiary, uint48 lockedUntil);
  event Unlock(uint256 tokenId, address beneficiary, uint256 amount);


  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//
  /**
    @param _jbx jbx address.
    @dev uri is empty since we will have svg support
  */
  constructor(IERC20 _jbx) 
  ERC721('JBveBanny', 'JBveBanny')
  EIP712('JBveBanny', '1')
 {
    jbx = _jbx;
  }

  function lock(address _account, uint256 _amount, uint48 _duration, address _beneficiary) external nonReentrant {
    if (msg.sender != _account) {
      revert INVALID_ACCOUNT();
    }
    if (jbx.balanceOf(_account) < _amount) {
      revert INSUFFICIENT_BALANCE();
    }
    if(jbx.allowance(msg.sender, address(this)) < _amount) {
       revert INSUFFICIENT_ALLOWANCE();
    }
    jbx.transferFrom(msg.sender, address(this), _amount);
    count += 1;
    uint48 _lockedUntil = uint48(block.timestamp) + _duration;
    uint256 packedValue;
    packedValue |= _amount << 8;
    packedValue |= _duration << 24;
    packedValue |= _lockedUntil << 40;
    _packedSpecs[count] = packedValue;
    emit Lock(_account, _amount, _duration, _beneficiary, _lockedUntil);
    _mint(_beneficiary, count);
  }

  function unlock(uint256 _tokenId, address _beneficiary) external nonReentrant {
    uint256 packedValue = _packedSpecs[_tokenId];
    uint256 _amount;
    uint48 _lockedUntil;
    _amount |= packedValue >> 8;
    _lockedUntil |= uint48(packedValue >> 40);
    if (block.timestamp <= _lockedUntil) {
      revert LOCK_PERIOD_NOT_OVER();
    }
    emit Unlock(_tokenId, _beneficiary, _amount);
    _burn(_tokenId);
    jbx.transfer(_beneficiary, _amount);

  }


  /**
   * @dev Computes the metadata url based on the id.
     @return dynamic uri based on the svg logic for that particular banny
  */
  function tokenURI() public view returns (string memory) {
    // svg logic where based on user stake we render the nft
  }
}
