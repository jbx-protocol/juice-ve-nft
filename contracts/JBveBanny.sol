// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './utils/ITokenUriResolver.sol';

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error INVALID_ACCOUNT();
error INSUFFICIENT_BALANCE();
error INSUFFICIENT_ALLOWANCE();
error LOCK_PERIOD_NOT_OVER();

/**
  @notice
  Allows any ERC20 Token Holders to stake their tokens and receive a Banny based on their stake and lock in period.
  @dev 
  Bannies are transferrable, will be burnt when the stake is claimed before or after the lock-in period ends.
  The Token URI will be determined by SVG for each banny category.
  Inherits from:
  ERC721Votes - for ERC721 and governance support.
  Ownable - for access control.
  ReentrancyGuard - for protection against external calls.
*/
contract JBveBanny is ERC721Votes, Ownable, ReentrancyGuard {
  event Lock(
    address account,
    uint256 amount,
    uint48 duration,
    address beneficiary,
    uint48 lockedUntil
  );

  event Unlock(uint256 tokenId, address beneficiary, uint256 amount);

  event ExtendLock(uint256 tokenId, uint48 updatedDuration);

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
    ERC20 Token Instance
  */
  IERC20 public immutable token;

  /** 
    @notice 
    Token URI Resolver Instance
  */
  ITokenUriResolver public uriResolver;

  /** 
    @notice 
    Banny id counter
  */
  uint256 public count;

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//
  /**
    @param _token Erc20 token address.
    @param _name Nft name.
    @param _symbol Nft symbol.
    @param _uriResolver Token uri resolver instance.
    @dev uri is empty since we will have svg support
  */
  constructor(
    IERC20 _token,
    string memory _name,
    string memory _symbol,
    ITokenUriResolver _uriResolver
  ) ERC721(_name, _symbol) EIP712('JBveBanny', '1') {
    token = _token;
    uriResolver = _uriResolver;
  }

  /**
    @notice
    Allows token holder to lock in their tokens in exchange for a banny.
    
    @param _account ERC20 Token Token Holder.
    @param _amount Lock Amount.
    @param _duration Lock time in seconds.
    @param _beneficiary Address to mint the banny.
  */
  function lock(
    address _account,
    uint256 _amount,
    uint48 _duration,
    address _beneficiary
  ) external nonReentrant {
    // Make sure the msg.sender is locking its own tokens.
    if (msg.sender != _account) {
      revert INVALID_ACCOUNT();
    }

    // Make sure the token balance of the account is enough to lock the specified _amount of tokens.
    if (token.balanceOf(_account) < _amount) {
      revert INSUFFICIENT_BALANCE();
    }

    // Make sure the sender has set enough allowance for this contract to transfer its tokens.
    if (token.allowance(msg.sender, address(this)) < _amount) {
      revert INSUFFICIENT_ALLOWANCE();
    }

    // Increment the number of ve positions that have been minted.
    count += 1;

    // Calculate the time when this lock will end (in seconds).
    uint48 _lockedUntil = uint48(block.timestamp) + _duration;

    // Store packed specification values for the ve position.
    // _amount in the bits 0-159.
    uint256 packedValue = _amount;
    // _duration in the bits 160-207.
    packedValue |= _duration << 160;
    // _lockedUntil in the bits 208-255.
    packedValue |= _lockedUntil << 208;
    _packedSpecs[count] = packedValue;

    // Mint the position for the beneficiary.
    _mint(_beneficiary, count);

    // Transfer the token to this contract where they'll be locked.
    token.transferFrom(msg.sender, address(this), _amount);

    // Emit event.
    emit Lock(_account, _amount, _duration, _beneficiary, _lockedUntil);
  }

  /**
    @notice
    Allows banny holders to burn their banny and get back the locked in amount.

    @param _tokenId Banny Id.
    @param _beneficiary Address to transfer the locked amount to.
  */
  function unlock(uint256 _tokenId, address _beneficiary) external nonReentrant {
    // Unpack the position specs for the probided tokenId.
    uint256 packedValue = _packedSpecs[_tokenId];
    // _amount in the bits 0-159.
    uint256 _amount = uint256(uint160(packedValue));
    // _lockedUntil in the bits 208-255.
    uint256 _lockedUntil = uint256(uint48(packedValue >> 208));

    // The lock must have expired.
    if (block.timestamp <= _lockedUntil) {
      revert LOCK_PERIOD_NOT_OVER();
    }

    // Burn the token.
    _burn(_tokenId);

    // Transfer the amount of locked tokens to beneficiary.
    token.transfer(_beneficiary, _amount);

    // Emit event.
    emit Unlock(_tokenId, _beneficiary, _amount);
  }

  /**
    @notice
    Allows banny holders to extend their token lock-in duration
    @param _tokenId Banny Id.
    @param _tokenId New lock-in duration.
  */
  function extendLock(uint256 _tokenId, uint48 _updatedDuration) external {
    // check is the msg.sender is the owner of the banny or not
    if (ownerOf(_tokenId) != msg.sender) {
      revert INVALID_ACCOUNT();
    }

    // fetch the stored packed value.
    uint256 packedValue = _packedSpecs[_tokenId];
    // get prev. duration value
    uint48 _duration = uint48(packedValue >> 160);
    // get prev. lockedUntil Value
    uint48 _lockedUntil = uint48(packedValue >> 208);
    // Calculate the updated time when this lock will end (in seconds).
    uint48 _updatedLockedUntil = (_lockedUntil + _updatedDuration) - _duration;
    // _duration in the bits 160-207.
    // update the value in these bits.
    packedValue |= _updatedDuration << 160;
    // _lockedUntil in the bits 208-255.
    // update the value in these bits.
    packedValue |= _updatedLockedUntil << 208;
    // update the mapping with new packed values
    _packedSpecs[_tokenId] = packedValue;
    emit ExtendLock(_tokenId, _updatedDuration);
  }

  /**
     @notice 
     Computes the metadata url based on the id.

     @param _tokenId TokenId of the Banny
     @return dynamic uri based on the svg logic for that particular banny
  */
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    // svg logic where based on user stake we render the nft
    uint256 packedValue = _packedSpecs[_tokenId];
    // _amount in the bits 0-159.
    uint256 _amount = uint256(uint160(packedValue));
    // _duration in the bits 160-207.
    uint256 _duration = uint256(uint48(packedValue));
    // _lockedUntil in the bits 208-255.
    uint256 _lockedUntil = uint256(uint48(packedValue >> 208));

    return uriResolver.tokenURI(_tokenId, _amount, _duration, _lockedUntil);
  }

  /**
    @notice
    Unpacks the packed specs of each banny based on token id.
    @param _tokenId Banny Id.
    Returns Locked in amount, lock-in duration and total lock-in period.
  */
  function getSpecs(uint256 _tokenId)
    external
    view
    returns (
      uint256 amount,
      uint256 duration,
      uint256 lockedUntil
    )
  {
    uint256 packedValue = _packedSpecs[_tokenId];
    // _amount in the bits 0-159.
    amount = uint256(uint160(packedValue));
    // _duration in the bits 160-207.
    duration = uint256(uint48(packedValue));
    // _lockedUntil in the bits 208-255.
    lockedUntil = uint256(uint48(packedValue >> 208));
  }
}
