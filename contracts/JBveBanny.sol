// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@paulrberg/contracts/math/PRBMath.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBTokenStore.sol';
import '@jbx-protocol/contracts-v2/contracts/abstract/JBOperatable.sol';

import './interfaces/IJBVeTokenUriResolver.sol';
import './libraries/JBStakingOperations.sol';
import './libraries/JBErrors.sol';

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error INVALID_ACCOUNT();

error INSUFFICIENT_ALLOWANCE();
error LOCK_PERIOD_NOT_OVER();
error TOKEN_MISMATCH();
error INVALID_LOCK_EXTENSION();

/**
  @notice
  Allows any JBToken holders to stake their tokens and receive a Banny based on their stake and lock in period.

  @dev 
  Bannies are transferrable, will be burnt when the stake is claimed before or after the lock-in period ends.
  The Token URI will be determined by SVG for each banny category.
  Inherits from:
  ERC721Votes - for ERC721 and governance support.
  Ownable - for access control.
  ReentrancyGuard - for protection against external calls.
*/
contract JBveBanny is ERC721Votes, ERC721Enumerable, Ownable, ReentrancyGuard, JBOperatable {
  event Lock(
    uint256 indexed tokenId,
    address indexed account,
    uint256 amount,
    uint256 duration,
    address beneficiary,
    uint256 lockedUntil,
    address caller
  );

  event Unlock(uint256 indexed tokenId, address beneficiary, uint256 amount, address caller);

  event ExtendLock(
    uint256 indexed tokenId,
    uint256 updatedDuration,
    uint256 updatedLockedUntil,
    address caller
  );

  event SetUriResolver(IJBVeTokenUriResolver indexed resolver, address caller);

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
    The maximum lock duration.
  */
  uint256 private immutable _maxLockDuration;

  /** 
    @notice 
    The options for lock durations.
  */
  uint256[] private _lockDurationOptions;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice 
    IJBToken Instance
  */
  IJBToken public token;

  /** 
    @notice 
    JBProject id.
  */
  uint256 public immutable projectId;

  /** 
    @notice 
    Token URI Resolver Instance
  */
  IJBVeTokenUriResolver public uriResolver;

  /** 
    @notice 
    The JBTokenStore where unclaimed tokens are accounted for.
  */
  IJBTokenStore public tokenStore;

  /** 
    @notice 
    Banny id counter
  */
  uint256 public count;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice
    The lock duration options

    @return An array of lock duration options, in seconds.
  */
  function lockDurationOptions() external view returns (uint256[] memory) {
    return _lockDurationOptions;
  }

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//

  /**
    @param _projectId The ID of the project.
    @param _name Nft name.
    @param _symbol Nft symbol.
    @param _uriResolver Token uri resolver instance.
    @param _tokenStore The JBTokenStore where unclaimed tokens are accounted for.
    @param __lockDurationOptions The lock options, in seconds, for lock durations.
  */
  constructor(
    uint256 _projectId,
    string memory _name,
    string memory _symbol,
    IJBVeTokenUriResolver _uriResolver,
    IJBTokenStore _tokenStore,
    IJBOperatorStore _operatorStore,
    uint256[] memory __lockDurationOptions
  ) ERC721(_name, _symbol) EIP712('JBveBanny', '1') JBOperatable(_operatorStore) {
    token = _tokenStore.tokenOf(_projectId);
    projectId = _projectId;
    uriResolver = _uriResolver;
    tokenStore = _tokenStore;
    _lockDurationOptions = __lockDurationOptions;

    // Save the max lock duration.
    uint256 _max = 0;
    for (uint256 _i; _i < _lockDurationOptions.length; _i++)
      if (_lockDurationOptions[_i] > _max) _max = _lockDurationOptions[_i];
    _maxLockDuration = _max;
  }

  /**
    @notice
    Allows token holder to lock in their tokens in exchange for a banny.

    @dev
    Only an account or a designated operator can lock its tokens.
    
    @param _account JBToken Holder.
    @param _amount Lock Amount.
    @param _duration Lock time in seconds.
    @param _beneficiary Address to mint the banny.
    @param _useJbToken A flag indicating if JBtokens are being locked. If false, unclaimed project tokens from the JBTokenStore will be locked.

    @return tokenId The tokenId for the new ve position.
  */
  function lock(
    address _account,
    uint256 _amount,
    uint256 _duration,
    address _beneficiary,
    bool _useJbToken
  )
    external
    nonReentrant
    requirePermission(_account, projectId, JBStakingOperations.LOCK)
    returns (uint256 tokenId)
  {
    if (_useJbToken) {
      // If a token wasn't set when this contract was deployed but is set now, set it.
      if (token == IJBToken(address(0)) && tokenStore.tokenOf(projectId) != IJBToken(address(0))) {
        token = tokenStore.tokenOf(projectId);
        // The project's token must not have changed since this token was originally set.
      } else if (tokenStore.tokenOf(projectId) != token) revert TOKEN_MISMATCH();
    }

    // Duration must match.
    if (!_isLockDurationAcceptable(_duration)) revert JBErrors.INVALID_LOCK_DURATION();

    // Make sure the token balance of the account is enough to lock the specified _amount of tokens.
    if (_useJbToken && token.balanceOf(_account, projectId) < _amount)
      revert JBErrors.INSUFFICIENT_BALANCE();
    else if (!_useJbToken && tokenStore.unclaimedBalanceOf(_account, projectId) < _amount)
      revert JBErrors.INSUFFICIENT_BALANCE();

    // Increment the number of ve positions that have been minted.
    tokenId = ++count;

    // Calculate the time when this lock will end (in seconds).
    uint256 _lockedUntil = block.timestamp + _duration;

    // Store packed specification values for the ve position.
    // _amount in the bits 0-151.
    uint256 packedValue = _amount;
    // _duration in the bits 152-199.
    packedValue |= _duration << 152;
    // _lockedUntil in the bits 200-247.
    packedValue |= _lockedUntil << 200;
    // _useJbToken in bit 248.
    if (_useJbToken) packedValue |= 1 << 248;

    _packedSpecs[tokenId] = packedValue;

    // Mint the position for the beneficiary.
    _safeMint(_beneficiary, tokenId);

    if (_useJbToken)
      // Transfer the token to this contract where they'll be locked.
      // Will revert if not enough allowance.
      token.transferFrom(projectId, msg.sender, address(this), _amount);
      // Transfer the token to this contract where they'll be locked.
      // Will revert if this contract isn't an opperator.
    else tokenStore.transferFrom(msg.sender, projectId, address(this), _amount);

    // Emit event.
    emit Lock(tokenId, _account, _amount, _duration, _beneficiary, _lockedUntil, msg.sender);
  }

  /**
    @notice
    Allows banny holders to burn their banny and get back the locked in amount.

    @dev
    Only an account or a designated operator can unlock its tokens.

    @param _tokenId Banny Id.
    @param _beneficiary Address to transfer the locked amount to.
  */
  function unlock(uint256 _tokenId, address _beneficiary)
    external
    nonReentrant
    requirePermission(ownerOf(_tokenId), projectId, JBStakingOperations.UNLOCK)
  {
    (uint256 _amount, , uint256 _lockedUntil, bool _useJbToken) = getSpecs(_tokenId);

    // The lock must have expired.
    if (block.timestamp <= _lockedUntil) revert LOCK_PERIOD_NOT_OVER();

    // Burn the token.
    _burn(_tokenId);

    if (_useJbToken)
      // Transfer the amount of locked tokens to beneficiary.
      token.transfer(projectId, _beneficiary, _amount);
      // Transfer the tokens from this contract.
    else tokenStore.transferFrom(_beneficiary, projectId, address(this), _amount);

    // Emit event.
    emit Unlock(_tokenId, _beneficiary, _amount, msg.sender);
  }

  /**
    @notice
    Allows banny holders to extend their token lock-in duration

    @dev
    Only an account or a designated operator can extend the lock of its tokens.

    @param _tokenId Banny Id.
    @param _updatedDuration New lock-in duration.
  */
  function extendLock(uint256 _tokenId, uint256 _updatedDuration)
    external
    nonReentrant
    requirePermission(ownerOf(_tokenId), projectId, JBStakingOperations.EXTEND_LOCK)
  {
    // Duration must match.
    if (!_isLockDurationAcceptable(_updatedDuration)) revert JBErrors.INVALID_LOCK_DURATION();

    (uint256 _amount, , uint256 _lockedUntil, bool _useJbToken) = getSpecs(_tokenId);

    // Calculate the updated time when this lock will end (in seconds).
    uint256 _updatedLockedUntil = block.timestamp + _updatedDuration;

    // The new lock must be greater than the current lock.
    if (_lockedUntil > _updatedLockedUntil) revert INVALID_LOCK_EXTENSION();

    // fetch the stored packed value.
    uint256 packedValue = _amount;
    // _duration in the bits 152-199.
    packedValue |= _updatedDuration << 152;
    // _lockedUntil in the bits 200-247.
    packedValue |= _updatedLockedUntil << 200;
    // _useJbToken in bit 248.
    if (_useJbToken) packedValue |= 1 << 248;

    _packedSpecs[_tokenId] = packedValue;

    emit ExtendLock(_tokenId, _updatedDuration, _updatedLockedUntil, msg.sender);
  }

  /**
     @notice 
     Allows the owner to set the uri resolver.

     @param _resolver The new URI resolver.
  */
  function setUriResolver(IJBVeTokenUriResolver _resolver) external onlyOwner {
    uriResolver = _resolver;
    emit SetUriResolver(_resolver, msg.sender);
  }

  /**
     @notice 
     Computes the metadata url based on the id.

     @param _tokenId TokenId of the Banny

     @return dynamic uri based on the svg logic for that particular banny
  */
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    (uint256 _amount, uint256 _duration, uint256 _lockedUntil, ) = getSpecs(_tokenId);
    return uriResolver.tokenURI(_tokenId, _amount, _duration, _lockedUntil, _lockDurationOptions);
  }

  /**
    @notice
    Unpacks the packed specs of each banny based on token id.

    @param _tokenId Banny Id.

    @return amount Locked amount
    @return duration Locked duration
    @return lockedUntil Locked until this timestamp.
    @return useJbToken If the locked tokens are JBTokens. 
  */
  function getSpecs(uint256 _tokenId)
    public
    view
    returns (
      uint256 amount,
      uint256 duration,
      uint256 lockedUntil,
      bool useJbToken
    )
  {
    uint256 _packedValue = _packedSpecs[_tokenId];
    // amount in the bits 0-151.
    amount = uint256(uint152(_packedValue));
    // duration in the bits 152-199.
    duration = uint256(uint48(_packedValue >> 152));
    // lockedUntil in the bits 200-247.
    lockedUntil = uint256(uint48(_packedValue >> 200));
    // useJbToken in the bits 248.
    useJbToken = (_packedValue >> 248) & 1 == 1;
  }

  /**
    @notice
    Gets the amount of voting units an account has given its locked positions.

    @param _account The account to get voting units of.

    @return units The amount of voting units the account has.
   */
  function _getVotingUnits(address _account) internal view override returns (uint256 units) {
    // Loop through all positions owned by the _account.
    for (uint256 _i; _i < balanceOf(_account); _i++) {
      // Get the token represented a positioned owned by the account.
      uint256 _tokenId = tokenOfOwnerByIndex(_account, _i);

      (uint256 _amount, , uint256 _lockedUntil, ) = getSpecs(_tokenId);

      // No voting units if the lock has expired.
      if (block.timestamp >= _lockedUntil) continue;

      // Voting balance for each token is a function of how much time is left on the lock.
      units += PRBMath.mulDiv(_amount, (_lockedUntil - block.timestamp), _maxLockDuration);
    }
  }

  /**
    @notice
    Returns a flag indicating if the provided duration is one of the lock duration options.

    @param _duration The duration to evaluate.

    @return A flag.
  */
  function _isLockDurationAcceptable(uint256 _duration) private view returns (bool) {
    for (uint256 _i; _i < _lockDurationOptions.length; _i++)
      if (_lockDurationOptions[_i] == _duration) return true;
    return false;
  }

  /**
    @dev Requires override. Calls super.
  */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(_interfaceId);
  }

  /**
    @dev Requires override. Calls super.
  */
  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721Votes, ERC721) {
    return super._afterTokenTransfer(_from, _to, _tokenId);
  }

  /**
    @dev Requires override. Calls super.
  */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    return super._beforeTokenTransfer(_from, _to, _tokenId);
  }
}
