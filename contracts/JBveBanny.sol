// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol'; 


//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error INVALID_ACCOUNT();
error INSUFFICIENT_BALANCE();
error INSUFFICIENT_ALLOWANCE();
error LOCK_PERIOD_NOT_OVER();

/**
  @notice
  Allows JBX Holders to stake their tokens and receive Jbx Banny based on their stake and lock in period.
  @dev 
  Bannies are transferrable, will be burnt when the stake is claimed before or after the lock-in period ends.
  The Token URI will be determined by SVG for each banny category.
  Inherits from:
  ERC721Votes - for ERC721 and governance support.
  Ownable - for access control.
  ReentrancyGuard - for protection against external calls.
*/
contract JBveBanny is ERC721Votes, Ownable, ReentrancyGuard {
  
  event Lock(address account, uint256 amount, uint48 duration, address beneficiary, uint48 lockedUntil);

  event Unlock(uint256 tokenId, address beneficiary, uint256 amount);

  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//
  /**
    @notice
    Tracks the specs of each tokenId which are basically locked amount, lock-in duration and total lock-in period.
  */
  mapping(uint256 => uint256) private _packedSpecs;


  /** 
    @notice 
    JBX Token Instance
  */
  IERC20 public immutable jbx;

  /** 
    @notice 
    Banny id counter
  */
  uint256 public count;


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


  /**
    @notice
    Allows jbx holder to lock in their tokens in exchange for a banny.
    @param _account Jbx Token Holder.
    @param _amount Lock Amount.
    @param _duration Lock time in seconds.
    @param _beneficiary Address to mint the banny.
  */
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

  /**
    @notice
    Allows banny holder to burn their banny and get back the locked in amount.
    @param _tokenId Banny Id.
    @param _beneficiary Address to transfer the locked amount to.
  */
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
     @param _tokenId TokenId of the Banny
     @return dynamic uri based on the svg logic for that particular banny
  */
  function tokenURI(uint256 _tokenId) public override view returns (string memory) {
    // svg logic where based on user stake we render the nft
    uint256 packedValue = _packedSpecs[_tokenId];
    uint256 _amount;
    uint48 _duration;
    uint48 _lockedUntil;
    _amount |= packedValue >> 8;
    _duration |= uint48(packedValue >> 24);
    _lockedUntil |= uint48(packedValue >> 40);
    // tokenURI logic not added since those details haven't been finalized
    return '';
  }

  /**
    @notice
    Unpacks the packed specs of each banny based on token id.
    @param _tokenId Banny Id.
    @return  Locked in amount, lock-in duration and total lock-in period.
  */
  function getPackedSpecs(uint256 _tokenId) external view returns(uint256, uint48, uint48) {
    uint256 packedValue = _packedSpecs[_tokenId];
    uint256 _amount;
    uint48 _duration;
    uint48 _lockedUntil;
    _amount |= packedValue >> 8;
    _duration |= uint48(packedValue >> 24);
    _lockedUntil |= uint48(packedValue >> 40);
    return (_amount, _duration, _lockedUntil);
  }
}
