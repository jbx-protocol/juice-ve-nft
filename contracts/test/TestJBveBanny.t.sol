// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './helpers/TestBaseWorkflow.t.sol';
import '../veERC721.sol';
import '../interfaces/IJBVeTokenUriResolver.sol';

contract JBveBannyTests is TestBaseWorkflow {
  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//
  JBveBanny private _jbveBanny;
  JBVeTokenUriResolver private _jbveTokenUriResolver;
  JBTokenStore private _jbTokenStore;
  JBController private _jbController;
  JBOperatorStore private _jbOperatorStore;
  address private _redemptionTerminal;
  uint256 private _projectId;
  address private _projectOwner;
  IJBToken _token;
  JBToken _paymentToken;

  //*********************************************************************//
  // --------------------------- test setup ---------------------------- //
  //*********************************************************************//
  function setUp() public override {
    // calling before each for TestBaseWorkflow
    super.setUp();
    // fetching instances deployed in the base workflow file
    _projectId = projectID();
    _jbTokenStore = jbTokenStore();
    _jbOperatorStore = jbOperatorStore();
    _jbveTokenUriResolver = jbveTokenUriResolver();
    _jbController = jbController();
    _redemptionTerminal = jbERC20PaymentTerminal();
    _paymentToken = jbToken();

    // lock duration options array to be used for mock deployment
    // All have to be dividable by weeks
    uint256[] memory _lockDurationOptions = new uint256[](3);
    _lockDurationOptions[0] = 1 weeks; // 1 week
    _lockDurationOptions[1] = 4 weeks; // 4 weeks
    _lockDurationOptions[2] = 12 weeks; // 12 weeks

    // JBveBanny
    _jbveBanny = new JBveBanny(
      _projectId,
      'Banny',
      'Banny',
      IJBVeTokenUriResolver(address(_jbveTokenUriResolver)),
      IJBTokenStore(address(_jbTokenStore)),
      IJBOperatorStore(address(_jbOperatorStore)),
      _lockDurationOptions
    );
  }

  function testConstructor() public {
    // All have to be dividable by weeks
    uint256[] memory _lockDurationOptions = new uint256[](3);
    _lockDurationOptions[0] = 1 weeks; // 1 week
    _lockDurationOptions[1] = 4 weeks; // 4 weeks
    _lockDurationOptions[2] = 12 weeks; // 12 weeks
    // assertion checks for constructor code
    assertEq(address(_jbTokenStore.tokenOf(_projectId)), address(_jbveBanny.token()));
    assertEq(address(_jbveTokenUriResolver), address(_jbveBanny.uriResolver()));
    assertEq(_projectId, _jbveBanny.projectId());
    assertEq(_lockDurationOptions[0], _jbveBanny.lockDurationOptions()[0]);
  }

  function mintIJBTokens() public returns (IJBToken) {
    IJBToken _jbToken = _jbTokenStore.tokenOf(_projectId);
    _projectOwner = projectOwner();
    evm.startPrank(_projectOwner);
    _jbController.mintTokensOf(_projectId, 100 ether, _projectOwner, 'Test Memo', true, true);
    _jbToken.approve(_projectId, address(_jbveBanny), 10 ether);
    return _jbToken;
  }

  function mintIJBTokensFor(address _account, uint256 _amount) public returns (IJBToken) {
    IJBToken _jbToken = _jbTokenStore.tokenOf(_projectId);
    _projectOwner = projectOwner();

    evm.startPrank(_projectOwner);
    // Mint tokens for project owner
    _jbController.mintTokensOf(_projectId, _amount * 10, _projectOwner, 'Test Memo', true, true);
    // Transfer tokens to account
    _jbToken.transfer(_projectId, _account, _amount);
    evm.stopPrank();

    // Approve accounts tokens for jbveBanny
    evm.prank(_account);
    _jbToken.approve(_projectId, address(_jbveBanny), _amount);

    return _jbToken;
  }

  function testLockWithJBToken() public {
    mintIJBTokens();
    _jbveBanny.lock(_projectOwner, 10 ether, 1 weeks, _projectOwner, true, false);
    (int128 _amount, , uint256 _duration, bool _useJbToken, bool _allowPublicExtension) = _jbveBanny
      .locked(1);
    assert(_jbveBanny.tokenVotingPowerAt(1, block.number) > 0);
    assertEq(_amount, 10 ether);
    assertEq(_duration, 1 weeks);
    assert(_useJbToken);
    assert(!_allowPublicExtension);
    assertEq(_jbveBanny.ownerOf(1), _projectOwner);
    (uint256 amount, uint256 duration, , bool isJbToken, ) = _jbveBanny.getSpecs(1);
    assertEq(amount, 10 ether);
    assertEq(duration, 1 weeks);
    assert(isJbToken);
  }

  function testUnlockingTokens() public {
    IJBToken _jbToken = mintIJBTokens();
    _jbveBanny.lock(_projectOwner, 10 ether, 1 weeks, _projectOwner, true, false);
    (, , uint256 _lockedUntil, , ) = _jbveBanny.getSpecs(1);
    evm.warp(_lockedUntil + 2);
    _jbveBanny.approve(address(_jbveBanny), 1);
    JBUnlockData[] memory unlocks = new JBUnlockData[](1);
    unlocks[0] = JBUnlockData(1, _projectOwner);
    _jbveBanny.unlock(unlocks);
    assert(_jbveBanny.tokenVotingPowerAt(1, block.number) == 0);
    (int128 _amount, uint256 end, , , ) = _jbveBanny.locked(1);
    assertEq(_amount, 0);
    assertEq(end, 0);
    assertEq(_jbToken.balanceOf(address(_jbveBanny), _projectId), 0);
  }

  function testExtendLock() public {
    mintIJBTokens();
    uint256 _tokenId = _jbveBanny.lock(_projectOwner, 10 ether, 1 weeks, _projectOwner, true, false);
    (, uint256 _duration, uint256 _lockedUntil, , ) = _jbveBanny.getSpecs(_tokenId);
    assertEq(_duration, 1 weeks);
    evm.warp(_lockedUntil + 2);
    uint256 votingPowerBeforeExtending = _jbveBanny.tokenVotingPowerAt(1, block.number);

    JBLockExtensionData[] memory extends = new JBLockExtensionData[](1);
    extends[0] = JBLockExtensionData(1, 2419200);
    _tokenId = _jbveBanny.extendLock(extends)[0];
    uint256 votingPowerAfterExtending = _jbveBanny.tokenVotingPowerAt(1, block.number);
    assert(votingPowerAfterExtending > votingPowerBeforeExtending);
    (, _duration, , , ) = _jbveBanny.getSpecs(_tokenId);
    assertEq(_duration, 2419200);
  }


  function testRedeem() public {
    mintIJBTokens();
    uint256 _tokenId = _jbveBanny.lock(_projectOwner, 10 ether, 1 weeks, _projectOwner, true, false);
    (, , uint256 _lockedUntil, , ) = _jbveBanny.getSpecs(_tokenId);
    evm.warp(_lockedUntil * 2);
    evm.stopPrank();

    evm.startPrank(address(_jbveBanny));
    uint256[] memory _permissionIndexes = new uint256[](1);
    _permissionIndexes[0] = JBOperations.BURN;
    jbOperatorStore().setOperator(
      JBOperatorData(address(_redemptionTerminal), _projectId, _permissionIndexes)
    );
    evm.stopPrank();

    evm.startPrank(_projectOwner);
    // adding overflow
    _paymentToken.approve(address(_redemptionTerminal), 20 ether);
     IJBPaymentTerminal(_redemptionTerminal).addToBalanceOf(
      _projectId,
      20 ether,
      address(0),
      'Forge test',
      new bytes(0)
    );

    JBRedeemData[] memory redeems = new JBRedeemData[](1);
    redeems[0] = JBRedeemData(
      _tokenId,
      address(0),
      1 ether,
      payable(_projectOwner),
      'test memo',
      '0x69',
      IJBRedemptionTerminal(_redemptionTerminal)
    );

    uint tokenStoreBalanceBeforeRedeem = _jbTokenStore.balanceOf(address(_jbveBanny), _projectId);
    uint jbTerminalTokenBalanceBeforeRedeem = _paymentToken.balanceOf(_projectOwner, _projectId);

    _jbveBanny.redeem(redeems);

    uint jbTerminalTokenBalanceAfterRedeem = _paymentToken.balanceOf(_projectOwner, _projectId);
    uint tokenStoreBalanceAfterRedeem = _jbTokenStore.balanceOf(address(_jbveBanny), _projectId);

    assert(tokenStoreBalanceBeforeRedeem > tokenStoreBalanceAfterRedeem);
    assert(jbTerminalTokenBalanceAfterRedeem > jbTerminalTokenBalanceBeforeRedeem);
  }
  function testScenarioWithInvalidLockDuration() public {
    mintIJBTokens();
    evm.expectRevert(abi.encodeWithSignature('INVALID_LOCK_DURATION()'));
    _jbveBanny.lock(_projectOwner, 10 ether, 864001, _projectOwner, true, false);
  }

  function testScenarioWithInsufficientBalance() public {
    mintIJBTokens();
    evm.expectRevert('ERC20: transfer amount exceeds allowance');
    _jbveBanny.lock(_projectOwner, 101 ether, 1 weeks, _projectOwner, true, false);
  }

  function testScenarioWhenLockPeriodIsNotOver() public {
    mintIJBTokens();
    _jbveBanny.lock(_projectOwner, 10 ether, 1 weeks, _projectOwner, true, false);
    (, , uint256 _lockedUntil, , ) = _jbveBanny.getSpecs(1);
    evm.warp(_lockedUntil - 2);
    _jbveBanny.approve(address(_jbveBanny), 1);
    evm.expectRevert(abi.encodeWithSignature('LOCK_PERIOD_NOT_OVER()'));
    JBUnlockData[] memory unlocks = new JBUnlockData[](1);
    unlocks[0] = JBUnlockData(1, _projectOwner);
    _jbveBanny.unlock(unlocks);
  }

  function testScenarioWithInvalidLockDurationWhenExtendingDuration() public {
    mintIJBTokens();
    _jbveBanny.lock(_projectOwner, 10 ether, 1 weeks, _projectOwner, true, false);
    (, uint256 _duration, uint256 _lockedUntil, , ) = _jbveBanny.getSpecs(1);
    assertEq(_duration, 1 weeks);
    evm.warp(_lockedUntil + 2);
    evm.expectRevert(abi.encodeWithSignature('INVALID_LOCK_DURATION()'));

    JBLockExtensionData[] memory extends = new JBLockExtensionData[](1);
    extends[0] = JBLockExtensionData(1, 2419201);
    _jbveBanny.extendLock(extends);
  }

  function testScenarioWithInvalidLockExtension() public {
    mintIJBTokens();
    _jbveBanny.lock(_projectOwner, 10 ether, 1 weeks, _projectOwner, true, false);
    (, uint256 _duration, uint256 _lockedUntil, , ) = _jbveBanny.getSpecs(1);
    assertEq(_duration, 1 weeks);
    evm.warp(_lockedUntil / 2);
    evm.expectRevert(abi.encodeWithSignature('INVALID_LOCK_EXTENSION()'));

    JBLockExtensionData[] memory extends = new JBLockExtensionData[](1);
    extends[0] = JBLockExtensionData(1, 2419200);
    _jbveBanny.extendLock(extends);
  }

  function testLockWithNonJbToken() public {
    _projectOwner = projectOwner();
    evm.startPrank(_projectOwner);
    _jbController.mintTokensOf(_projectId, 100 ether, _projectOwner, 'Test Memo', false, true);
    uint256[] memory _permissionIndexes = new uint256[](1);
    _permissionIndexes[0] = JBOperations.TRANSFER;
    jbOperatorStore().setOperator(
      JBOperatorData(address(_jbveBanny), _projectId, _permissionIndexes)
    );
    _jbveBanny.lock(_projectOwner, 10 ether, 1 weeks, _projectOwner, false, false);
    assert(_jbveBanny.tokenVotingPowerAt(1, block.number) > 0);
    (int128 _amount, , uint256 _duration, bool _useJbToken, bool _allowPublicExtension) = _jbveBanny
      .locked(1);
    assertEq(_amount, 10 ether);
    assertEq(_duration, 1 weeks);
    assert(!_useJbToken);
    assert(!_allowPublicExtension);
    assertEq(_jbveBanny.ownerOf(1), _projectOwner);
    (uint256 amount, uint256 duration, , , ) = _jbveBanny.getSpecs(1);
    assertEq(amount, 10 ether);
    assertEq(duration, 1 weeks);
  }

  function testLockVotingPowerIncreasesIfLockedLonger() public {
    mintIJBTokens();

    _jbveBanny.lock(_projectOwner, 5 ether, 1 weeks, _projectOwner, true, false);
    assert(_jbveBanny.tokenVotingPowerAt(1, block.number) > 0);

    _jbveBanny.lock(_projectOwner, 5 ether, 2419200, _projectOwner, true, false);
    assert(_jbveBanny.tokenVotingPowerAt(2, block.number) > 0);

    // Since lock-2 is 4x as long as lock-1, it should have x4 the voting power
    // (might be slightly more or less due to rounding to nearest week)
    assertGt(
      _jbveBanny.tokenVotingPowerAt(2, block.number),
      _jbveBanny.tokenVotingPowerAt(1, block.number) * 4
    );
  }

  function testLockVotingPowerDecreasesOverTime() public {
    mintIJBTokens();

    uint256 _steps = 4;
    uint256 _secondsPerBlock = 1;
    uint256 _lastVotingPower = 0;
    uint256 _tokenId = _jbveBanny.lock(_projectOwner, 10 ether, 1 weeks, _projectOwner, true, false);
    (, uint256 _end, , , ) = _jbveBanny.locked(_tokenId);

    uint256 _timePerStep = (_end - block.timestamp) / _steps + 1;
    uint256 _blocksPerStep = _timePerStep / _secondsPerBlock;

    // Increase the current timestamp and verify that the voting power keeps decreasing
    uint256 _currentTime = block.timestamp;
    uint256 _currentBlock = block.number;

    for (uint256 _i; _i < _steps; _i++) {
      uint256 _currentVotingPower = _jbveBanny.tokenVotingPowerAt(_tokenId, _currentBlock);

      if (_lastVotingPower != 0) {
        assertLt(_currentVotingPower, _lastVotingPower);
      }
      assertTrue(_currentVotingPower > 0);

      _lastVotingPower = _currentVotingPower;

      _currentTime += _timePerStep;
      _currentBlock += _blocksPerStep; // Assuming 15 second block times

      evm.warp(_currentTime);
      evm.roll(_currentBlock);
    }

    // After the lock has expired it should be 0
    assert(_jbveBanny.tokenVotingPowerAt(_tokenId, _currentBlock) == 0);
  }

  function testLockVotingPowerHistoricLookupIsCorrect() public {
    mintIJBTokens();

    uint256 _steps = 4;
    uint256 _secondsPerBlock = 1;
    uint256 _lastVotingPower = 0;
    uint256 _tokenId = _jbveBanny.lock(_projectOwner, 10 ether, 1 weeks, _projectOwner, true, false);
    (, uint256 _end, , , ) = _jbveBanny.locked(_tokenId);

    uint256[] memory _historicVotingPower = new uint256[](_steps);
    uint256[] memory _historicVotingPowerBlocks = new uint256[](_steps);

    uint256 _timePerStep = (_end - block.timestamp) / _steps + 1;
    uint256 _blocksPerStep = _timePerStep / _secondsPerBlock;

    // Increase the current timestamp and verify that the voting power keeps decreasing
    uint256 _currentTime = block.timestamp;
    uint256 _currentBlock = block.number;

    // Check the voting power and check if it decreases in comparison with the previous check
    // Store the `_currentVotingPower`
    for (uint256 _i; _i < _steps; _i++) {
      uint256 _currentVotingPower = _jbveBanny.tokenVotingPowerAt(_tokenId, _currentBlock);

      if (_lastVotingPower != 0) {
        assertLt(_currentVotingPower, _lastVotingPower);
      }
      assertTrue(_currentVotingPower > 0);

      _historicVotingPower[_i] = _currentVotingPower;
      _historicVotingPowerBlocks[_i] = _currentBlock;
      _lastVotingPower = _currentVotingPower;

      _currentTime += _timePerStep;
      _currentBlock += _blocksPerStep; // Assuming 15 second block times

      evm.warp(_currentTime);
      evm.roll(_currentBlock);
    }

    // After the lock has expired it should be 0
    assert(_jbveBanny.tokenVotingPowerAt(_tokenId, _currentBlock) == 0);

    // Use the stored `_currentVotingPower` and `_currentBlock` and perform historic lookups for each
    // Make sure the historic lookup and (at the time) current values are the same
    for (uint256 _i = 0; _i < _historicVotingPower.length; _i++) {
      uint256 _votingPowerAtBlock = _jbveBanny.tokenVotingPowerAt(
        _tokenId,
        _historicVotingPowerBlocks[_i]
      );

      assertEq(_historicVotingPower[_i], _votingPowerAtBlock);
      assert(_historicVotingPower[_i] > 0 && _votingPowerAtBlock > 0);
    }
  }

  function testVotingPowerGetsActivatedIfMintedForSelf() public {
    address _user = address(0xf00ba6);
    mintIJBTokensFor(_user, 5 ether);

    // Check the users voting power before creating the new lock
    uint256 _initialVotingPower = _jbveBanny.getVotes(_user);

    // Lock the tokens
    evm.prank(_user);
    _jbveBanny.lock(_user, 5 ether, 1 weeks, _user, true, false);

    // Did the user receive the voting power
    assert(_jbveBanny.getVotes(_user) - _initialVotingPower > 0);
  }

  function testVotingPowerDoesNotGetActivatedIfMintedForOtherUser() public {
    address _user = address(0xf00ba6);
    mintIJBTokensFor(_user, 5 ether);

    // Check the users voting power before creating the new lock
    uint256 _initialVotingPower = _jbveBanny.getVotes(_projectOwner);

    // Lock the tokens
    evm.prank(_user);
    _jbveBanny.lock(_user, 5 ether, 1 weeks, _projectOwner, true, false);

    // The user should now have an increased voting power
    assert(_jbveBanny.getVotes(_projectOwner) - _initialVotingPower == 0);
  }

  function testActivatingVotingPower() public {
    address _user = address(0xf00ba6);
    mintIJBTokensFor(_user, 5 ether);

    // Check the users voting power before creating the new lock
    uint256 _initialVotingPower = _jbveBanny.getVotes(_projectOwner);

    // Lock the tokens
    evm.prank(_user);
    uint256 _tokenId = _jbveBanny.lock(_user, 5 ether, 1 weeks, _projectOwner, true, false);

    // There should be no change
    assert(_jbveBanny.getVotes(_projectOwner) - _initialVotingPower == 0);

    // As the benificiary enable the voting power of the token
    evm.prank(_projectOwner);
    _jbveBanny.activateVotingPower(_tokenId);

    // Should now be higher
    assert(_jbveBanny.getVotes(_projectOwner) - _initialVotingPower > 0);
  }

  function testVotingPowerGetsDisabledOnTransfer() public {
    address _userA = address(0xf00);
    address _userB = address(0xba6);
    mintIJBTokensFor(_userA, 5 ether);

    // Check the users voting power before creating the new lock
    uint256 _initialVotingPower = _jbveBanny.getVotes(_userA);

    // Lock the tokens and mint new NFT for user A
    evm.prank(_userA);
    uint256 _tokenId = _jbveBanny.lock(_userA, 5 ether, 1 weeks, _userA, true, false);

    // Get the new voting power of the user
    uint256 _afterMintVotingPower = _jbveBanny.getVotes(_userA);

    // UserA should have received voting power
    assert(_afterMintVotingPower - _initialVotingPower > 0);

    // Get the voting power of user B
    uint256 _userBVotingPowerBeforeTransfer = _jbveBanny.getVotes(_userB);

    // Have user A tranfer the token to user B
    evm.prank(_userA);
    _jbveBanny.safeTransferFrom(_userA, _userB, _tokenId);

    // Get the updated voting powers for both users
    uint256 _userAVotingPowerAfterTransfer = _jbveBanny.getVotes(_userA);
    uint256 _userBVotingPowerAfterTransfer = _jbveBanny.getVotes(_userB);

    // User A should now be back to the same voting power as before the mint
    assertEq(_userAVotingPowerAfterTransfer, _initialVotingPower);
    // User B's voting power should not have changed (since it needs to be activated manually)
    assertEq(_userBVotingPowerAfterTransfer, _userBVotingPowerBeforeTransfer);
  }
}
