// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@paulrberg/contracts/math/PRBMath.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBTokenStore.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBPayoutRedemptionPaymentTerminal.sol';
import '@jbx-protocol/contracts-v2/contracts/abstract/JBOperatable.sol';

import './structs/JBAllowPublicExtensionData.sol';
import './structs/JBLockExtensionData.sol';
import './interfaces/IJBVeTokenUriResolver.sol';
import './libraries/JBStakingOperations.sol';
import './libraries/JBErrors.sol';

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
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_ACCOUNT();
  error NON_EXISTENT_TOKEN();
  error INSUFFICIENT_ALLOWANCE();
  error LOCK_PERIOD_NOT_OVER();
  error TOKEN_MISMATCH();
  error INVALID_PUBLIC_EXTENSION_FLAG_VALUE();
  error INVALID_LOCK_EXTENSION();

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
    uint256 indexed oldTokenID,
    uint256 indexed newTokenID,
    uint256 updatedDuration,
    uint256 updatedLockedUntil,
    address caller
  );

  event SetAllowPublicExtension(uint256 indexed tokenId, bool allowPublicExtension, address caller);

  event Redeem(
    uint256 indexed tokenId,
    address holder,
    address beneficiary,
    uint256 tokenCount,
    uint256 claimedAmount,
    string memo,
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

  //*********************************************************************//
  // --------------------- external transactions ----------------------- //
  //*********************************************************************//

  /**
    @notice
    Allows token holder to lock in their tokens in exchange for a banny.

    @dev
    Only an account or a designated operator can lock its tokens.
    
    @param _account JBToken Holder.
    @param _count Lock Amount.
    @param _duration Lock time in seconds.
    @param _beneficiary Address to mint the banny.
    @param _useJbToken A flag indicating if JBtokens are being locked. If false, unclaimed project tokens from the JBTokenStore will be locked.
    @param _allowPublicExtension A flag indicating if the locked position can be extended by anyone.

    @return tokenId The tokenId for the new ve position.
  */
  function lock(
    address _account,
    uint256 _count,
    uint256 _duration,
    address _beneficiary,
    bool _useJbToken,
    bool _allowPublicExtension
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

    // Make sure the token balance of the account is enough to lock the specified _count of tokens.
    if (_useJbToken && token.balanceOf(_account, projectId) < _count)
      revert JBErrors.INSUFFICIENT_BALANCE();
    else if (!_useJbToken && tokenStore.unclaimedBalanceOf(_account, projectId) < _count)
      revert JBErrors.INSUFFICIENT_BALANCE();

    // Increment the number of ve positions that have been minted.
    tokenId = ++count;

    // Calculate the time when this lock will end (in seconds).
    uint256 _lockedUntil = block.timestamp + _duration;
    _setSpecs(tokenId, _count, _duration, _lockedUntil, _useJbToken, _allowPublicExtension);
    // Mint the position for the beneficiary.
    _safeMint(_beneficiary, tokenId);

    if (_useJbToken)
      // Transfer the token to this contract where they'll be locked.
      // Will revert if not enough allowance.
      token.transferFrom(projectId, msg.sender, address(this), _count);
      // Transfer the token to this contract where they'll be locked.
      // Will revert if this contract isn't an opperator.
    else tokenStore.transferFrom(msg.sender, projectId, address(this), _count);

    // Emit event.
    emit Lock(tokenId, _account, _count, _duration, _beneficiary, _lockedUntil, msg.sender);
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
    // Get the specs for the token ID.
    (uint256 _count, , uint256 _lockedUntil, bool _useJbToken, ) = getSpecs(_tokenId);

    // The lock must have expired.
    if (block.timestamp <= _lockedUntil) revert LOCK_PERIOD_NOT_OVER();

    // Burn the token.
    _burn(_tokenId);

    if (_useJbToken)
      // Transfer the amount of locked tokens to beneficiary.
      token.transfer(projectId, _beneficiary, _count);
      // Transfer the tokens from this contract.
    else tokenStore.transferFrom(_beneficiary, projectId, address(this), _count);

    // Emit event.
    emit Unlock(_tokenId, _beneficiary, _count, msg.sender);
  }

  /**
    @notice
    Allows banny holders to extend their token lock-in durations.

    @dev
    If the position being extended isn't set to allow public extension, only an operator account or a designated operator can extend the lock of its tokens.

    @param _lockExtensionData An array of locks to extend.
  */
  function extendLock(JBLockExtensionData[] calldata _lockExtensionData) external nonReentrant returns(uint256[] memory newTokenIds) {
    newTokenIds = new uint256[](_lockExtensionData.length);

    for (uint256 _i; _i < _lockExtensionData.length; _i++) {
      // Get a reference to the extension being iterated.
      JBLockExtensionData memory _data = _lockExtensionData[_i];

      // Duration must match.
      if (!_isLockDurationAcceptable(_data.updatedDuration))
        revert JBErrors.INVALID_LOCK_DURATION();

      // Get the specs for the token ID.
      (
        uint256 _count,
        ,
        uint256 _lockedUntil,
        bool _useJbToken,
        bool _allowPublicExtension
      ) = getSpecs(_data.tokenId);

      // Get the current owner
      address _ownerOf = ownerOf(_data.tokenId);

      if (!_allowPublicExtension)
        // If the operation isn't allowed publicly, check if the msg.sender is either the position owner or is an operator.
        _requirePermission(_ownerOf, projectId, JBStakingOperations.EXTEND_LOCK);

      // No time remaining if the lock has expired.
      uint256 _timeRemaining = (block.timestamp >= _lockedUntil)
        ? 0
        : _lockedUntil - block.timestamp;

      // Calculate the updated time when this lock will end (in seconds).
      uint256 _updatedLockedUntil = block.timestamp + _data.updatedDuration - _timeRemaining;

      // The new lock must be greater than the current lock.
      if (_lockedUntil > _updatedLockedUntil) revert INVALID_LOCK_EXTENSION();

      // Burn the old NFT
      _burn(_data.tokenId);

      // Increment the number of ve positions that have been minted.
      uint256 newTokenId = ++count;
      newTokenIds[_i] = newTokenId;

      // Set the specifications of the new lock
      _setSpecs(newTokenId, _count, _data.updatedDuration, _updatedLockedUntil, _useJbToken, _allowPublicExtension);

      // Mint the new NFT
      _safeMint(_ownerOf, newTokenId);

      emit ExtendLock(_data.tokenId, newTokenId, _data.updatedDuration, _updatedLockedUntil, msg.sender);
    }
  }

  /**
    @notice
    Allows banny holders to set whether or not anyone in the public can extend their locked position.

    @dev
    Only an owner account or a designated operator can extend the lock of its tokens.

    @param _allowPublicExtensionData An array of locks to extend.
  */
  function setAllowPublicExtension(JBAllowPublicExtensionData[] calldata _allowPublicExtensionData)
    external
    nonReentrant
  {
    for (uint256 _i; _i < _allowPublicExtensionData.length; _i++) {
      // Get a reference to the extension being iterated.
      JBAllowPublicExtensionData memory _data = _allowPublicExtensionData[_i];

      if (!_data.allowPublicExtension) {
        revert INVALID_PUBLIC_EXTENSION_FLAG_VALUE();
      }
      // Get the specs for the token ID.
      (uint256 _count, uint256 _duration, uint256 _lockedUntil, bool _useJbToken, ) = getSpecs(
        _data.tokenId
      );

      // Check if the msg.sender is either the position owner or is an operator.
      _requirePermission(
        ownerOf(_data.tokenId),
        projectId,
        JBStakingOperations.SET_PUBLIC_EXTENSION_FLAG
      );

      // fetch the stored packed value.
      uint256 packedValue = _count;
      // _duration in the bits 152-199.
      packedValue |= _duration << 152;
      // _lockedUntil in the bits 200-247.
      packedValue |= _lockedUntil << 200;
      // _useJbToken in bit 248.
      if (_useJbToken) packedValue |= 1 << 248;
      // _allowPublicExtension in bit 249.
      if (_data.allowPublicExtension) packedValue |= 1 << 249;

      _packedSpecs[_data.tokenId] = packedValue;

      emit SetAllowPublicExtension(_data.tokenId, _data.allowPublicExtension, msg.sender);
    }
  }

  /**
    @notice
    Unlock the position and redeem the locked tokens.

    @dev
    Only an account or a designated operator can unlock its tokens.

    @param _tokenId Banny Id.
    @param _token The token to be reclaimed from the redemption.
    @param _minReturnedTokens The minimum amount of terminal tokens expected in return, as a fixed point number with the same amount of decimals as the terminal.
    @param _beneficiary The address to send the terminal tokens to.
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Bytes to send along to the data source and delegate, if provided.
  */
  function redeem(
    uint256 _tokenId,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string memory _memo,
    bytes memory _metadata,
    IJBRedemptionTerminal _terminal
  ) external nonReentrant {
    {
      // Check the permissions scoped to prevent stack too deep
      _requirePermission(ownerOf(_tokenId), projectId, JBStakingOperations.REDEEM);
    }

    // Get the specs for the token ID.
    (uint256 _count, , uint256 _lockedUntil, , ) = getSpecs(_tokenId);

    // The lock must have expired.
    if (block.timestamp <= _lockedUntil) revert LOCK_PERIOD_NOT_OVER();

    // Get a reference to the owner of the position.
    address _owner = ownerOf(_tokenId);

    // Burn the token.
    _burn(_tokenId);

    // Redeem the locked tokens to reclaim treasury funds.
    uint256 _reclaimedAmount = _terminal.redeemTokensOf(
      address(this),
      projectId,
      _count,
      _token,
      _minReturnedTokens,
      _beneficiary,
      _memo,
      _metadata
    );

    // Emit event.
    emit Redeem(_tokenId, _owner, _beneficiary, _count, _reclaimedAmount, _memo, msg.sender);
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
    (uint256 _count, uint256 _duration, uint256 _lockedUntil, , ) = getSpecs(_tokenId);
    return uriResolver.tokenURI(_tokenId, _count, _duration, _lockedUntil, _lockDurationOptions);
  }

  /**
    @notice
    Unpacks the packed specs of each banny based on token id.

    @param _tokenId Banny Id.

    @return amount Locked token count.
    @return duration Locked duration.
    @return lockedUntil Locked until this timestamp.
    @return useJbToken If the locked tokens are JBTokens. 
    @return allowPublicExtension If the locked position can be extended by anyone. 
  */
  function getSpecs(uint256 _tokenId)
    public
    view
    returns (
      uint256 amount,
      uint256 duration,
      uint256 lockedUntil,
      bool useJbToken,
      bool allowPublicExtension
    )
  {
    uint256 _packedValue = _packedSpecs[_tokenId];
    if (_packedValue == 0) revert NON_EXISTENT_TOKEN();

    // amount in the bits 0-151.
    amount = uint256(uint152(_packedValue));
    // duration in the bits 152-199.
    duration = uint256(uint48(_packedValue >> 152));
    // lockedUntil in the bits 200-247.
    lockedUntil = uint256(uint48(_packedValue >> 200));
    // useJbToken in the bits 248.
    useJbToken = (_packedValue >> 248) & 1 == 1;
    // allowPublicExtension in the bits 249.
    allowPublicExtension = (_packedValue >> 249) & 1 == 1;
  }

  //*********************************************************************//
  // --------------------- private helper functions -------------------- //
  //*********************************************************************//

  /**
    @notice
    Set the specs for a tokenId

    @param _tokenId to set the specs for
    @param _amount Locked token count.
    @param _duration Locked duration.
    @param _lockedUntil Locked until this timestamp.
    @param _useJbToken If the locked tokens are JBTokens. 
    @param _allowPublicExtension If the locked position can be extended by anyone. 

    @return packedValue the specs packed into a single uint256
  */
  function _setSpecs(
    uint256 _tokenId,
    uint256 _amount,
    uint256 _duration,
    uint256 _lockedUntil,
    bool _useJbToken,
    bool _allowPublicExtension
  ) private returns (uint256 packedValue) {
    // Store packed specification values for the ve position.
    // _amount in the bits 0-151.
    packedValue = _amount;
    // _duration in the bits 152-199.
    packedValue |= _duration << 152;
    // _lockedUntil in the bits 200-247.
    packedValue |= _lockedUntil << 200;
    // _useJbToken in bit 248.
    if (_useJbToken) packedValue |= 1 << 248;
    // _allowPublicExtension in bit 249.
    if (_allowPublicExtension) packedValue |= 1 << 249;

    _packedSpecs[_tokenId] = packedValue;
    return packedValue;
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

      (uint256 _count, , uint256 _lockedUntil, , ) = getSpecs(_tokenId);

      // No voting units if the lock has expired.
      if (block.timestamp >= _lockedUntil) continue;

      // Voting balance for each token is a function of how much time is left on the lock.
      units += PRBMath.mulDiv(_count, (_lockedUntil - block.timestamp), _maxLockDuration);
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

  /**
    @notice
    Deletes the storage related to the _tokenId and burns the token

    @param _tokenId The token to burn
   */
  function _burn(uint256 _tokenId) internal virtual override {
    // Delete the storage related to the TokenID
    delete _packedSpecs[_tokenId];
    // Delete the TokenID
    super._burn(_tokenId);
  }
}
