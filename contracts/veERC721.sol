// SPDX-License-Identifier: MIT
// Solidity and NFT version of Curve Finance - VotingEscrow
// (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy)
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/governance/utils/IVotes.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime:
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime (4 years?)

struct HistoricOwnership {
  uint256 ownedAtBlock;
  address account;
}

struct LockedBalance {
  int128 amount;
  uint256 end;
}

struct Point {
  int128 bias;
  int128 slope; // - dweight / dt
  uint256 ts;
  uint256 blk;
}

abstract contract veERC721 is ERC721, IVotes {
  using Counters for Counters.Counter;

  uint256 private constant _week = 86400 * 7; // all future times are rounded by week
  uint256 private constant _maxTime = 4 * 365 * 86400; // 4 years
  uint256 private constant _multiplier = 10**18;

  IERC20 immutable token;

  uint256 public epoch;
  Point[] public pointHistory;
  Counters.Counter nOfLocks;
  mapping(uint256 => LockedBalance) locked;
  mapping(uint256 => Point[]) tokenPointHistory;
  mapping(uint256 => uint256) tokenPointEpoch;
  mapping(uint256 => int128) slopeChanges; // time -> signed slope change

  // The owners of a specific tokenId ordered by Time (old to new)
  mapping(uint256 => HistoricOwnership[]) private _historicOwnership;
  // The tokens an address has had ownership of at some point in time
  mapping(address => uint256[]) private _hasOwned;

  Counters.Counter private _tokenIdCounter;

  constructor(
    address _token,
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {
    token = IERC20(_token);

    pointHistory.push(Point(0, 0, block.timestamp, block.number));

    //_checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
  }

  /**
    @dev Requires override. Calls super.
  */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override {
    if (_to != address(0)) {
      _hasOwned[_to].push(_tokenId);
    }

    _historicOwnership[_tokenId].push(HistoricOwnership(block.number, _to));

    return super._afterTokenTransfer(_from, _to, _tokenId);
  }

  /**
    @notice Calculate the current voting power of an address
    @param _account account to calculate
  */
  function getVotes(address _account) public view virtual override returns (uint256) {
    return getPastVotes(_account, block.number);
  }

  /**
    @notice Calculate the voting power of an address at a specific block
    @param _account account to calculate
    @param _block Block to calculate the voting power at
  */
  function getPastVotes(address _account, uint256 _block)
    public
    view
    virtual
    override
    returns (uint256 votingPower)
  {
    for (uint256 _i; _i < _hasOwned[_account].length; _i++) {
      uint256 _tokenId = _hasOwned[_account][_i];
      uint256 _count = _historicOwnership[_tokenId].length;

      for (uint256 _j = _count; _j >= 1; _j--) {
        HistoricOwnership storage _ownership = _historicOwnership[_tokenId][_j - 1];
        if (_ownership.ownedAtBlock > _block) {
          continue;
        }

        if (_ownership.ownedAtBlock <= _block && _ownership.account == _account) {
          votingPower += tokenVotingPowerAt(_tokenId, _block);
        }

        break;
      }
    }
  }

  /**   
    @notice Measure voting power of a tokenId at block height `_block`
    @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    @param _tokenId TokenID
    @param _block Block to calculate the voting power at
    @return power Voting power
  */
  function tokenVotingPowerAt(uint256 _tokenId, uint256 _block)
    public
    view
    returns (uint256 power)
  {
    require(_block <= block.number);

    // Binary search
    uint256 _min;
    uint256 _max = tokenPointEpoch[_tokenId];
    for (uint256 _i; _i <= 128; _i++) {
      // Will be always enough for 128-bit numbers
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (tokenPointHistory[_tokenId][_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }

    Point memory _upoint = tokenPointHistory[_tokenId][_min];

    uint256 _maxEpoch = epoch;
    uint256 _epoch = findBlockEpoch(_block, _maxEpoch);
    Point memory _point_0 = pointHistory[_epoch];
    uint256 _d_block;
    uint256 _d_t;
    if (_epoch < _maxEpoch) {
      Point memory _point_1 = pointHistory[_epoch + 1];
      _d_block = _point_1.blk - _point_0.blk;
      _d_t = _point_1.ts - _point_0.ts;
    } else {
      _d_block = block.number - _point_0.blk;
      _d_t = block.timestamp - _point_0.ts;
    }
    uint256 block_time = _point_0.ts;
    if (_d_block != 0) {
      block_time += (_d_t * (_block - _point_0.blk)) / _d_block;
    }

    _upoint.bias -= _upoint.slope * (int128(int256(block_time)) - int128(int256(_upoint.ts)));
    if (_upoint.bias >= 0) {
      return uint256(uint128(_upoint.bias));
    } else {
      return 0;
    }
  }

  /**
    @notice Calculate total voting power at some point in the past
    @param _point The point (bias/slope) to start search from
    @param _timestamp Time to calculate the total voting power at
    @return Total voting power at that time
  */
  function supplyAtPoint(Point memory _point, uint256 _timestamp) public view returns (uint256) {
    Point memory _last_point = _point;
    uint256 _t_i = (_last_point.ts / _week) * _week;

    for (uint256 _i; _i <= 255; _i++) {
      int128 _d_slope;
      _t_i += _week;
      if (_t_i > _timestamp) {
        _t_i = _timestamp;
      } else {
        _d_slope = slopeChanges[_t_i];
      }
      _last_point.bias -=
        _last_point.slope *
        (int128(int256(_t_i)) - int128(int256(_last_point.ts)));
      if (_t_i == _timestamp) {
        break;
      }
      _last_point.slope += _d_slope;
      _last_point.ts = _t_i;
    }

    if (_last_point.bias < 0) {
      return 0;
    }

    return uint256(uint128(_last_point.bias));
  }

  /**
   * @dev Returns the delegate that `account` has chosen.
   */
  function delegates(address account) external pure override returns (address) {
    // delagation is not supported
    return account;
  }

  function delegate(address delegatee) external override {}

  /**
   * @dev Delegates votes from signer to `delegatee`.
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {}

  /**
    @notice Calculate total voting power
    @return Total voting power
  */
  function totalSupply() external view virtual returns (uint256) {
    Point memory _point = pointHistory[epoch];
    return supplyAtPoint(_point, block.timestamp);
  }

  /**
    @notice Calculate total voting power at some point in the past
    @param _blockNumber Block to calculate the total voting power at
    @return Total voting power at `_blockNumber`
  */
  function getPastTotalSupply(uint256 _blockNumber)
    external
    view
    virtual
    override
    returns (uint256)
  {
    uint256 _epoch = epoch;
    uint256 _target_epoch = findBlockEpoch(_blockNumber, _epoch);

    uint256 _dt;
    Point memory _point = pointHistory[_target_epoch];

    if (_target_epoch < _epoch) {
      Point memory _pointNext = pointHistory[_target_epoch + 1];
      if (_point.blk != _pointNext.blk) {
        _dt =
          ((_blockNumber - _point.blk) * (_pointNext.ts - _point.ts)) /
          (_pointNext.blk - _point.blk);
      }
    } else {
      if (_point.blk != block.number) {
        _dt =
          ((_blockNumber - _point.blk) * (block.timestamp - _point.ts)) /
          (block.number - _point.blk);
      }
    }

    return supplyAtPoint(_point, _point.ts + _dt);
  }

  /**
    @notice Binary search to estimate timestamp for block number
    @param _block Block to find
    @param _max_epoch Don't go beyond this epoch
    @return Approximate timestamp for block
  */
  function findBlockEpoch(uint256 _block, uint256 _max_epoch) public view returns (uint256) {
    uint256 _min;
    uint256 _max = _max_epoch;

    for (uint256 _i; _i <= 128; _i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (pointHistory[_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }

    return _min;
  }

  /** 
    @notice Mint a new veNFT and lock tokens
    @param _transferFrom where should we transfer the tokens from
    @param _beneficiary who will receive the newly minted veNFT
    @param _value Amount to deposit
    @param _unlockTime Time when to unlock the tokens
    @return tokenID The newly minted TokenID
  */
  function _mintLock(
    address _transferFrom,
    address _beneficiary,
    uint256 _value,
    uint256 _unlockTime
  ) internal returns (uint256 tokenID) {
    // TODO: Add messages/custom errors
    require(_value > 0);
    require(_unlockTime > block.timestamp);
    require(_unlockTime <= block.timestamp + _maxTime);

    // Locktime is rounded down to weeks
    uint256 _unlockTimeRounded = (_unlockTime / _week) * _week;
    // Increment first then take new number, this way we keep tokenId 0 unused
    nOfLocks.increment();
    tokenID = nOfLocks.current();
    // Create new lock and transfer tokens tokens
    _depositInto(tokenID, _transferFrom, _value, _unlockTimeRounded, LockedBalance(0, 0));
    // Mint and send veNFT
    _safeMint(_beneficiary, tokenID);
  }

  /** 
    @param _tokenId veNFT TokenID
    @param _from where should we transfer the tokens from
    @param _value Amount to deposit
    @param _unlock_time New time when to unlock the tokens, or 0 if unchanged
    @param _balance Previous locked amount / timestamp
  */
  function _depositInto(
    uint256 _tokenId,
    address _from,
    uint256 _value,
    uint256 _unlock_time,
    LockedBalance memory _balance
  ) internal {
    LockedBalance memory _locked = _balance;
    LockedBalance memory _old_locked = _balance;

    // Adding to existing lock, or if a lock is expired - creating a new one
    _locked.amount += int128(int256(_value));
    if (_unlock_time != 0) {
      _locked.end = _unlock_time;
    }
    locked[_tokenId] = _locked;

    // Possibilities:
    // Both old_locked.end could be current or expired (>/< block.timestamp)
    // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
    // _locked.end > block.timestamp (always)
    _checkpoint(_tokenId, _old_locked, _locked);

    if (_value != 0 && _from != address(this)) {
      // TODO: Perform SafeTransferFrom
      token.transferFrom(_from, address(this), _value);
    }
  }

  /** 
    @notice Record global and per-user data to checkpoint
    @param _tokenId TokenID. No token checkpoint if 0
    @param _old_locked Pevious locked amount / end lock time for the token
    @param _new_locked New locked amount / end lock time for the token
  */
  function _checkpoint(
    uint256 _tokenId,
    LockedBalance memory _old_locked,
    LockedBalance memory _new_locked
  ) internal {
    Point memory _u_old;
    Point memory _u_new;
    int128 _old_dslope;
    int128 _new_dslope;
    uint256 _epoch = epoch;

    if (_tokenId != 0) {
      // Calculate slopes and biases
      // Kept at zero when they have to
      if (_old_locked.end > block.timestamp && _old_locked.amount > 0) {
        _u_old.slope = _old_locked.amount / int128(int256(_maxTime));
        _u_old.bias =
          _u_old.slope *
          int128(int256(_old_locked.end)) -
          int128(int256(block.timestamp));
      }

      if (_new_locked.end > block.timestamp && _new_locked.amount > 0) {
        _u_new.slope = _new_locked.amount / int128(int256(_maxTime));
        _u_new.bias =
          _u_new.slope *
          int128(int256(_new_locked.end)) -
          int128(int256(block.timestamp));
      }

      // Read values of scheduled changes in the slope
      // _old_locked.end can be in the past and in the future
      // _new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
      _old_dslope = slopeChanges[_old_locked.end];
      if (_new_locked.end != 0) {
        if (_new_locked.end == _old_locked.end) {
          _new_dslope = _old_dslope;
        } else {
          _new_dslope = slopeChanges[_new_locked.end];
        }
      }
    }

    Point memory _last_point = Point(0, 0, block.timestamp, block.number);
    if (_epoch > 0) {
      _last_point = pointHistory[_epoch];
    }
    uint256 _last_checkpoint = _last_point.ts;
    // initial_last_point is used for extrapolation to calculate block number
    // (approximately, for *At methods) and save them
    // as we cannot figure that out exactly from inside the contract
    Point memory _initial_last_point = _last_point;
    uint256 _block_slope; // dblock/dt
    if (block.timestamp > _last_point.ts) {
      _block_slope =
        (_multiplier * (block.number - _last_point.blk)) /
        (block.timestamp - _last_point.ts);
    }
    // If last point is already recorded in this block, slope=0
    // But that's ok b/c we know the block in such case

    // Go over weeks to fill history and calculate what the current point is
    uint256 _t_i = (_last_checkpoint / _week) * _week;
    for (uint256 _i; _i <= 255; _i++) {
      // Hopefully it won't happen that this won't get used in 5 years!
      // If it does, users will be able to withdraw but vote weight will be broken
      _t_i += _week;
      int128 _d_slope;
      if (_t_i > block.timestamp) {
        _t_i = block.timestamp;
      } else {
        _d_slope = slopeChanges[_t_i];
      }
      _last_point.bias -=
        _last_point.slope *
        (int128(int256(_t_i)) - int128(int256(_last_checkpoint)));
      _last_point.slope += _d_slope;
      if (_last_point.bias < 0) {
        // This can happen
        _last_point.bias = 0;
      }
      if (_last_point.slope < 0) {
        // This cannot happen - just in case
        _last_point.slope = 0;
      }
      _last_checkpoint = _t_i;
      _last_point.ts = _t_i;
      _last_point.blk =
        _initial_last_point.blk +
        (_block_slope * (_t_i - _initial_last_point.ts)) /
        _multiplier;
      _epoch += 1;
      if (_t_i == block.timestamp) {
        _last_point.blk = block.number;
        break;
      } else {
        //pointHistory[_epoch] = _last_point;
        _setEpochPoint(_epoch, _last_point);
      }
    }

    epoch = _epoch;
    // Now point_history is filled until t=now

    if (_tokenId != 0) {
      // If last point was in this block, the slope change has been applied already
      // But in such case we have 0 slope(s)
      _last_point.slope += (_u_new.slope - _u_old.slope);
      _last_point.bias += (_u_new.bias - _u_old.bias);
      if (_last_point.slope < 0) {
        _last_point.slope = 0;
      }
      if (_last_point.bias < 0) {
        _last_point.bias = 0;
      }
    }

    // Record the changed point into history
    _setEpochPoint(_epoch, _last_point);
    //pointHistory[_epoch] = _last_point;

    if (_tokenId != 0) {
      // Schedule the slope changes (slope is going down)
      // We subtract new_user_slope from [new_locked.end]
      // and add old_user_slope to [old_locked.end]
      if (_old_locked.end > block.timestamp) {
        // old_dslope was <something> - u_old.slope, so we cancel that
        _old_dslope += _u_old.slope;
        if (_new_locked.end == _old_locked.end) {
          _old_dslope -= _u_new.slope; // It was a new deposit, not extension
        }
      }
      if (_new_locked.end > block.timestamp) {
        if (_new_locked.end > _old_locked.end) {
          _new_dslope -= _u_new.slope; // old slope disappeared at this point
          slopeChanges[_new_locked.end] = _new_dslope;
        } // else: we recorded it already in old_dslope
      }

      // Now handle token history
      _u_new.ts = block.timestamp;
      _u_new.blk = block.number;
      _setTokenEpoch(_tokenId, _u_new); // Moved to method to prevent stack too deep
    }
  }

  function _setEpochPoint(uint256 _epoch, Point memory _point) private {
    if (pointHistory.length == _epoch) {
      pointHistory.push(_point);
    } else {
      pointHistory[_epoch] = _point;
    }
  }

  function _setTokenEpoch(uint256 _tokenId, Point memory _point) private {
    uint256 _token_epoch = ++tokenPointEpoch[_tokenId];
    // Checkpoints expect epoch ID to be equal to the key, so we insert empty at key 0
    if (_token_epoch == 1) {
      tokenPointHistory[_tokenId].push();
    }

    tokenPointHistory[_tokenId].push(_point);
  }
}
