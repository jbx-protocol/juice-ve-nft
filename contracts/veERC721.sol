// SPDX-License-Identifier: GPL-2.0-or-later
// Solidity and NFT version of Curve Finance - VotingEscrow
// (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy)
pragma solidity 0.8.6;

// Converted into solidity by:
// Primary Author(s)
//  Travis Moore: https://github.com/FortisFortuna
// Reviewer(s) / Contributor(s)
//  Jason Huan: https://github.com/jasonhuan
//  Sam Kazemian: https://github.com/samkazemian
//  Frax Finance - https://github.com/FraxFinance
// Original idea and credit:
//  Curve Finance's veCRV
//  https://resources.curve.fi/faq/vote-locking-boost
//  https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
//  This is a Solidity version converted from Vyper by the Frax team
//  Almost all of the logic / algorithms are the Curve team's

//@notice Votes have a weight depending on time, so that users are
//        committed to the future of (whatever they are voting for)
//@dev Vote weight decays linearly over time. Lock time cannot be
//     more than `MAXTIME` (3 years).

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
//       maxtime (3 years?)

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/governance/utils/IVotes.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

abstract contract veERC721 is ERC721Enumerable, IVotes {
  using SafeERC20 for IERC20;

  /* ========== CUSTOM ERRORS ========== */
  error DelegationNotSupported();

  /* ========== STATE VARIABLES ========== */
  address public token;
  uint256 public supply;

  // The owners of a specific tokenId ordered by Time (old to new)
  mapping(uint256 => HistoricVotingPower[]) internal _historicVotingPower;
  // All the tokens an address has received voting power from at some point in time
  mapping(address => uint256[]) internal _receivedVotingPower;

  uint256 public epoch;
  mapping(uint256 => LockedBalance) public locked;
  Point[100000000000000000000000000000] public point_history; // epoch -> unsigned point
  mapping(uint256 => Point[1000000000]) public token_point_history;
  mapping(uint256 => uint256) public token_point_epoch;
  mapping(uint256 => int128) public slope_changes; // time -> signed slope change

  int128 public constant DEPOSIT_FOR_TYPE = 0;
  int128 public constant CREATE_LOCK_TYPE = 1;
  int128 public constant INCREASE_LOCK_AMOUNT = 2;
  int128 public constant INCREASE_UNLOCK_TIME = 3;

  uint256 public constant WEEK = 7 * 86400; // all future times are rounded by week
  uint256 public constant MAXTIME = 3 * 365 * 86400; // 3 years
  uint256 public constant MULTIPLIER = 10**18;

  // We cannot really do block numbers per se b/c slope is per time, not per block
  // and per block could be fairly bad b/c Ethereum changes blocktimes.
  // What we can do is to extrapolate ***At functions
  struct Point {
    int128 bias;
    int128 slope; // dweight / dt
    uint256 ts;
    uint256 blk; // block
  }

  struct LockedBalance {
    int128 amount;
    uint256 end;
    bool useJbToken;
    bool allowPublicExtension;
  }

  struct HistoricVotingPower {
    uint256 receivedAtBlock;
    address account;
  }

  /* ========== CONSTRUCTOR ========== */
  /**
   * @notice Contract constructor
   * @param _name Nft name.
   * @param _symbol Nft symbol.
   */
  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    point_history[0].blk = block.number;
    point_history[0].ts = block.timestamp;
  }

  /* ========== VIEWS ========== */

  // Constant structs not allowed yet, so this will have to do
  function EMPTY_POINT_FACTORY() internal pure returns (Point memory) {
    return Point({bias: 0, slope: 0, ts: 0, blk: 0});
  }

  // Constant structs not allowed yet, so this will have to do
  function EMPTY_LOCKED_BALANCE_FACTORY() internal pure returns (LockedBalance memory) {
    return LockedBalance({amount: 0, end: 0, useJbToken: false, allowPublicExtension: false});
  }

  /**
   * @notice Get the most recently recorded rate of voting power decrease for `addr`
   * @param _tokenId The token ID
   * @return Value of the slope
   */
  function get_last_token_slope(uint256 _tokenId) external view returns (int128) {
    uint256 tepoch = token_point_epoch[_tokenId];
    return token_point_history[_tokenId][tepoch].slope;
  }

  /**
   * @notice Get the timestamp for checkpoint `_idx` for `_addr`
   * @param _tokenId The token ID
   * @param _idx Tokens epoch number
   * @return Epoch time of the checkpoint
   */
  function user_point_history__ts(uint256 _tokenId, uint256 _idx) external view returns (uint256) {
    return token_point_history[_tokenId][_idx].ts;
  }

  /**
   * @notice Get timestamp when `_addr`'s lock finishes
   * @param _tokenId The token ID
   * @return Epoch time of the lock end
   */
  function locked__end(uint256 _tokenId) external view returns (uint256) {
    return locked[_tokenId].end;
  }

  /**
    @notice Calculate the current voting power of an address
    @param _account account to calculate
  */
  function getVotes(address _account) public view override returns (uint256 votingPower) {
    for (uint256 _i; _i < balanceOf(_account); _i++) {
      // TODO: should we make the mapping 'internal' so we can access it directly?
      uint256 _tokenId = tokenOfOwnerByIndex(_account, _i);
      uint256 _epoch = token_point_epoch[_tokenId];

      // Every initialised token should have an epoch of 1
      if (_epoch == 0) {
        continue;
      } else {
        Point memory last_point = token_point_history[_tokenId][_epoch];
        last_point.bias -=
          last_point.slope *
          (int128(int256(block.timestamp)) - int128(int256(last_point.ts)));
        if (last_point.bias < 0) {
          last_point.bias = 0;
        }

        votingPower += uint256(uint128(last_point.bias));
      }
    }
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
    for (uint256 _i; _i < _receivedVotingPower[_account].length; _i++) {
      uint256 _tokenId = _receivedVotingPower[_account][_i];
      uint256 _count = _historicVotingPower[_tokenId].length;

      for (uint256 _j = _count; _j >= 1; _j--) {
        HistoricVotingPower storage _voting_power = _historicVotingPower[_tokenId][_j - 1];
        if (_voting_power.receivedAtBlock > _block) {
          continue;
        }

        if (_voting_power.receivedAtBlock <= _block && _voting_power.account == _account) {
          votingPower += tokenVotingPowerAt(_tokenId, _block);
        }

        break;
      }
    }
  }

  /**
   * @notice Measure voting power of `addr` at block height `_block`
   * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
   * @param _tokenId The token ID
   * @param _block Block to calculate the voting power at
   * @return Voting power
   */
  function tokenVotingPowerAt(uint256 _tokenId, uint256 _block) public view returns (uint256) {
    // Copying and pasting totalSupply code because Vyper cannot pass by
    // reference yet
    require(_block <= block.number);

    // Binary search
    uint256 _min = 0;
    uint256 _max = token_point_epoch[_tokenId];

    // Will be always enough for 128-bit numbers
    for (uint256 i = 0; i < 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (token_point_history[_tokenId][_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }

    Point memory upoint = token_point_history[_tokenId][_min];

    uint256 max_epoch = epoch;
    uint256 _epoch = find_block_epoch(_block, max_epoch);
    Point memory point_0 = point_history[_epoch];
    uint256 d_block = 0;
    uint256 d_t = 0;

    if (_epoch < max_epoch) {
      Point memory point_1 = point_history[_epoch + 1];
      d_block = point_1.blk - point_0.blk;
      d_t = point_1.ts - point_0.ts;
    } else {
      d_block = block.number - point_0.blk;
      d_t = block.timestamp - point_0.ts;
    }

    uint256 block_time = point_0.ts;
    if (d_block != 0) {
      block_time += (d_t * (_block - point_0.blk)) / d_block;
    }

    upoint.bias -= upoint.slope * (int128(int256(block_time)) - int128(int256(upoint.ts)));
    if (upoint.bias >= 0) {
      return uint256(uint128(upoint.bias));
    } else {
      return 0;
    }
  }

  /**
    @notice Calculate total voting power at some point in the past
    @param _block Block to calculate the total voting power at
    @return Total voting power at `_block`
  */
  function getPastTotalSupply(uint256 _block) external view override returns (uint256) {
    require(_block <= block.number);
    uint256 _epoch = epoch;
    uint256 target_epoch = find_block_epoch(_block, _epoch);

    Point memory point = point_history[target_epoch];
    uint256 dt = 0;

    if (target_epoch < _epoch) {
      Point memory point_next = point_history[target_epoch + 1];
      if (point.blk != point_next.blk) {
        dt = ((_block - point.blk) * (point_next.ts - point.ts)) / (point_next.blk - point.blk);
      }
    } else {
      if (point.blk != block.number) {
        dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
      }
    }

    // Now dt contains info on how far are we beyond point
    return supply_at(point, point.ts + dt);
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    @dev Requires override. Calls super.
  */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override {
    // Make sure this is not a mint
    if (_from != address(0)) {
      // This is a transfer, disable voting power (if active)
      uint256 _historyLength = _historicVotingPower[_tokenId].length;
      if (_historyLength > 0) {
        HistoricVotingPower memory _latestVotingPower = _historicVotingPower[_tokenId][
          _historyLength - 1
        ];
        // Check if the voting power is already disabled, otherwise disable it now
        if (_latestVotingPower.account != address(0)) {
          _historicVotingPower[_tokenId].push(HistoricVotingPower(block.number, address(0)));
        }
      }
    }

    return super._afterTokenTransfer(_from, _to, _tokenId);
  }

  /**
   * @notice Record global and per-token data to checkpoint
   * @param _tokenId The token ID. No token checkpoint if 0
   * @param old_locked Previous locked amount / end lock time for the user
   * @param new_locked New locked amount / end lock time for the user
   */
  function _checkpoint(
    uint256 _tokenId,
    LockedBalance memory old_locked,
    LockedBalance memory new_locked
  ) internal {
    Point memory u_old = EMPTY_POINT_FACTORY();
    Point memory u_new = EMPTY_POINT_FACTORY();
    int128 old_dslope = 0;
    int128 new_dslope = 0;
    uint256 _epoch = epoch;

    if (_tokenId != 0) {
      // Calculate slopes and biases
      // Kept at zero when they have to
      if ((old_locked.end > block.timestamp) && (old_locked.amount > 0)) {
        u_old.slope = old_locked.amount / int128(int256(MAXTIME));
        u_old.bias =
          u_old.slope *
          (int128(int256(old_locked.end)) - int128(int256(block.timestamp)));
      }

      if ((new_locked.end > block.timestamp) && (new_locked.amount > 0)) {
        u_new.slope = new_locked.amount / int128(int256(MAXTIME));
        u_new.bias =
          u_new.slope *
          (int128(int256(new_locked.end)) - int128(int256(block.timestamp)));
      }

      // Read values of scheduled changes in the slope
      // old_locked.end can be in the past and in the future
      // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
      old_dslope = slope_changes[old_locked.end];
      if (new_locked.end != 0) {
        if (new_locked.end == old_locked.end) {
          new_dslope = old_dslope;
        } else {
          new_dslope = slope_changes[new_locked.end];
        }
      }
    }

    Point memory last_point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
    if (_epoch > 0) {
      last_point = point_history[_epoch];
    }
    uint256 last_checkpoint = last_point.ts;

    // initial_last_point is used for extrapolation to calculate block number
    // (approximately, for *At methods) and save them
    // as we cannot figure that out exactly from inside the contract
    Point memory initial_last_point = last_point;
    uint256 block_slope = 0; // dblock/dt
    if (block.timestamp > last_point.ts) {
      block_slope =
        (MULTIPLIER * (block.number - last_point.blk)) /
        (block.timestamp - last_point.ts);
    }

    // If last point is already recorded in this block, slope=0
    // But that's ok b/c we know the block in such case

    // Go over weeks to fill history and calculate what the current point is
    uint256 t_i = (last_checkpoint / WEEK) * WEEK;
    for (uint256 i = 0; i < 255; i++) {
      // Hopefully it won't happen that this won't get used in 4 years!
      // If it does, users will be able to withdraw but vote weight will be broken
      t_i += WEEK;
      int128 d_slope = 0;
      if (t_i > block.timestamp) {
        t_i = block.timestamp;
      } else {
        d_slope = slope_changes[t_i];
      }
      last_point.bias -= last_point.slope * (int128(int256(t_i)) - int128(int256(last_checkpoint)));
      last_point.slope += d_slope;
      if (last_point.bias < 0) {
        last_point.bias = 0; // This can happen
      }
      if (last_point.slope < 0) {
        last_point.slope = 0; // This cannot happen - just in case
      }
      last_checkpoint = t_i;
      last_point.ts = t_i;
      last_point.blk =
        initial_last_point.blk +
        (block_slope * (t_i - initial_last_point.ts)) /
        MULTIPLIER;
      _epoch += 1;
      if (t_i == block.timestamp) {
        last_point.blk = block.number;
        break;
      } else {
        point_history[_epoch] = last_point;
      }
    }

    epoch = _epoch;
    // Now point_history is filled until t=now

    if (_tokenId != 0) {
      // If last point was in this block, the slope change has been applied already
      // But in such case we have 0 slope(s)
      last_point.slope += (u_new.slope - u_old.slope);
      last_point.bias += (u_new.bias - u_old.bias);
      if (last_point.slope < 0) {
        last_point.slope = 0;
      }
      if (last_point.bias < 0) {
        last_point.bias = 0;
      }
    }

    // Record the changed point into history
    point_history[_epoch] = last_point;

    if (_tokenId != 0) {
      // Schedule the slope changes (slope is going down)
      // We subtract new_user_slope from [new_locked.end]
      // and add old_user_slope to [old_locked.end]
      if (old_locked.end > block.timestamp) {
        // old_dslope was <something> - u_old.slope, so we cancel that
        old_dslope += u_old.slope;
        if (new_locked.end == old_locked.end) {
          old_dslope -= u_new.slope; // It was a new deposit, not extension
        }
        slope_changes[old_locked.end] = old_dslope;
      }

      if (new_locked.end > block.timestamp) {
        if (new_locked.end > old_locked.end) {
          new_dslope -= u_new.slope; // old slope disappeared at this point
          slope_changes[new_locked.end] = new_dslope;
        }
        // else: we recorded it already in old_dslope
      }

      // Now handle user history
      // Second function needed for 'stack too deep' issues
      _checkpoint_part_two(_tokenId, u_new.bias, u_new.slope);
    }
  }

  /**
   * @notice Needed for 'stack too deep' issues in _checkpoint()
   * @param _tokenId User's wallet address. No token checkpoint if 0
   * @param _bias from unew
   * @param _slope from unew
   */
  function _checkpoint_part_two(
    uint256 _tokenId,
    int128 _bias,
    int128 _slope
  ) internal {
    uint256 token_epoch = token_point_epoch[_tokenId] + 1;

    token_point_epoch[_tokenId] = token_epoch;
    token_point_history[_tokenId][token_epoch] = Point({
      bias: _bias,
      slope: _slope,
      ts: block.timestamp,
      blk: block.number
    });
  }

  /**
   * @notice Deposit and lock tokens
   * @param _depositFrom The user to withdraw tokens from
   * @param _tokenId The tokenID to lock for
   * @param _value Amount to deposit
   * @param unlock_time New time when to unlock the tokens, or 0 if unchanged
   * @param locked_balance Previous locked amount / timestamp
   */
  function _deposit_for(
    address _depositFrom,
    uint256 _tokenId,
    uint256 _value,
    uint256 unlock_time,
    LockedBalance memory locked_balance,
    int128 _type
  ) internal {
    LockedBalance memory _locked = locked_balance;
    uint256 supply_before = supply;

    supply = supply_before + _value;
    LockedBalance memory old_locked = _locked;
    // Adding to existing lock, or if a lock is expired - creating a new one
    _locked.amount += int128(int256(_value));
    if (unlock_time != 0) {
      _locked.end = unlock_time;
    }
    locked[_tokenId] = _locked;

    // Possibilities:
    // Both old_locked.end could be current or expired (>/< block.timestamp)
    // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
    // _locked.end > block.timestamp (always)
    _checkpoint(_tokenId, old_locked, _locked);

    if (_value != 0) {
      assert(IERC20(token).transferFrom(_depositFrom, address(this), _value));
    }

    emit Deposit(_depositFrom, _value, _locked.end, _type, block.timestamp);
    emit Supply(supply_before, supply_before + _value);
  }

  // /**
  //  * @notice Withdraw all tokens for a TokenId
  //  * @dev Only possible if the lock has expired
  //  */
  // function _withdraw(uint256 _tokenId, address _recipient) internal {
  //   LockedBalance memory _locked = locked[_tokenId];
  //   require(block.timestamp >= _locked.end, 'The lock did not expire');
  //   uint256 value = uint256(uint128(_locked.amount));

  //   LockedBalance memory old_locked = _locked;
  //   _locked.end = 0;
  //   _locked.amount = 0;
  //   locked[_tokenId] = _locked;
  //   uint256 supply_before = supply;
  //   supply = supply_before - value;

  //   // old_locked can have either expired <= timestamp or zero end
  //   // _locked has only 0 end
  //   // Both can have >= 0 amount
  //   _checkpoint(_tokenId, old_locked, _locked);

  //   require(IERC20(token).transfer(_recipient, value));

  //   emit Withdraw(_recipient, value, block.timestamp);
  //   emit Supply(supply_before, supply_before - value);
  // }

  function _newLock(uint256 _tokenId, LockedBalance memory _lock) internal {
    // round end date to nearest week
    _lock.end = (_lock.end / WEEK) * WEEK;

    LockedBalance memory _old_lock = locked[_tokenId];
    locked[_tokenId] = _lock;

    _checkpoint(_tokenId, _old_lock, _lock);
  }

  /**
    @dev burns the token and checkpoints the changes in locked balances
   */
  function _burn(uint256 _tokenId) internal virtual override {
    LockedBalance memory _locked = locked[_tokenId];
    LockedBalance memory old_locked = _locked;
    _locked.end = 0;
    _locked.amount = 0;
    locked[_tokenId] = _locked;

    // TODO: Should we update supply?

    // old_locked can have either expired <= timestamp or zero end
    // _locked has only 0 end
    // Both can have >= 0 amount
    _checkpoint(_tokenId, old_locked, _locked);

    super._burn(_tokenId);
  }

  // The following ERC20/minime-compatible methods are not real balanceOf and supply!
  // They measure the weights for the purpose of voting, so they don't represent
  // real coins.
  /**
   * @notice Binary search to estimate timestamp for block number
   * @param _block Block to find
   * @param max_epoch Don't go beyond this epoch
   * @return Approximate timestamp for block
   */
  function find_block_epoch(uint256 _block, uint256 max_epoch) internal view returns (uint256) {
    // Binary search
    uint256 _min = 0;
    uint256 _max = max_epoch;

    // Will be always enough for 128-bit numbers
    for (uint256 i = 0; i < 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (point_history[_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }

    return _min;
  }

  /**
   * @notice Calculate total voting power at some point in the past
   * @param point The point (bias/slope) to start search from
   * @param t Time to calculate the total voting power at
   * @return Total voting power at that time
   */
  function supply_at(Point memory point, uint256 t) internal view returns (uint256) {
    Point memory last_point = point;
    uint256 t_i = (last_point.ts / WEEK) * WEEK;

    for (uint256 i = 0; i < 255; i++) {
      t_i += WEEK;
      int128 d_slope = 0;
      if (t_i > t) {
        t_i = t;
      } else {
        d_slope = slope_changes[t_i];
      }
      last_point.bias -= last_point.slope * (int128(int256(t_i)) - int128(int256(last_point.ts)));
      if (t_i == t) {
        break;
      }
      last_point.slope += d_slope;
      last_point.ts = t_i;
    }

    if (last_point.bias < 0) {
      last_point.bias = 0;
    }
    return uint256(uint128(last_point.bias));
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Activates the voting power of a token
   * @dev Voting power gets disabled when a token is transferred, this prevents a gas DOS attack
   * @param _tokenId The token to activate
   */
  function activateVotingPower(uint256 _tokenId) external {
    require(msg.sender == ownerOf(_tokenId));

    // We track all the tokens a user has received voting power over at some point
    // To lower gas usage we check if
    bool _alreadyRegistered;
    for (uint256 _i; _i < _receivedVotingPower[msg.sender].length; _i++) {
      uint256 _currentTokenId = _receivedVotingPower[msg.sender][_i];
      if (_tokenId == _currentTokenId) {
        _alreadyRegistered = true;
        break;
      }
    }
    // If the token has not been registerd for this user, register it
    if (!_alreadyRegistered) {
      _receivedVotingPower[msg.sender].push(_tokenId);
    }

    uint256 _historicVotingPowerLength = _historicVotingPower[_tokenId].length;
    if (_historicVotingPowerLength > 0) {
      HistoricVotingPower memory _latestVotingPower = _historicVotingPower[_tokenId][
        _historicVotingPowerLength - 1
      ];
      // Prevents multiple activations of the same token in 1 block
      require(
        _latestVotingPower.receivedAtBlock < block.number,
        'Voting power already enabled this block'
      );
      require(_latestVotingPower.account != msg.sender, 'Voting power is already enabled');
    }

    // Activate the voting power
    _historicVotingPower[_tokenId].push(HistoricVotingPower(block.number, msg.sender));
  }

  /**
   * @notice Record global data to checkpoint
   */
  function checkpoint() external {
    _checkpoint(0, EMPTY_LOCKED_BALANCE_FACTORY(), EMPTY_LOCKED_BALANCE_FACTORY());
  }

  /**
   * @dev Not supported by this contract, required for interface
   */
  function delegates(address) external view override returns (address) {
    revert DelegationNotSupported();
  }

  /**
   * @dev Not supported by this contract, required for interface
   */
  function delegate(address) external override {
    revert DelegationNotSupported();
  }

  /**
   * @dev Not supported by this contract, required for interface
   */
  function delegateBySig(
    address,
    uint256,
    uint256,
    uint8,
    bytes32,
    bytes32
  ) external override {
    revert DelegationNotSupported();
  }

  /* ========== EVENTS ========== */

  event Recovered(address token, uint256 amount);
  event Deposit(
    address indexed provider,
    uint256 value,
    uint256 indexed locktime,
    int128 _type,
    uint256 ts
  );
  event Withdraw(address indexed provider, uint256 value, uint256 ts);
  event Supply(uint256 prevSupply, uint256 supply);
}
