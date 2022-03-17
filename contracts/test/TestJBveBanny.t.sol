// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './helpers/TestBaseWorkflow.t.sol';
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
  uint256 private _projectId;
  address private _projectOwner;

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

    // lock duration options array to be used for mock deployment
    uint256[] memory _lockDurationOptions = new uint256[](3);
    _lockDurationOptions[0] = 864000;
    _lockDurationOptions[1] = 2160000;
    _lockDurationOptions[2] = 8640000;

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
    uint256[] memory _lockDurationOptions = new uint256[](3);
    _lockDurationOptions[0] = 864000;
    _lockDurationOptions[1] = 2160000;
    _lockDurationOptions[2] = 8640000;
    // assertion checks for constructor code
    assertEq(address(_jbTokenStore.tokenOf(_projectId)), address(_jbveBanny.token()));
    assertEq(address(_jbveTokenUriResolver), address(_jbveBanny.uriResolver()));
    assertEq(_projectId, _jbveBanny.projectId());
    assertEq(_lockDurationOptions[0], _jbveBanny.lockDurationOptions(0));
  }

  function testLockWithJBToken() public {
    IJBToken _token = _jbTokenStore.tokenOf(_projectId);
    _projectOwner = projectOwner();
    evm.startPrank(_projectOwner);
    _jbController.mintTokensOf(_projectId, 100 ether, _projectOwner, 'Test Memo', true, true);
    _token.approve(_projectId, address(_jbveBanny), 10 ether);
    _jbveBanny.lock(_projectOwner, 10 ether, 864000, _projectOwner, true);
    assertEq(_jbveBanny.ownerOf(1), _projectOwner);
    (uint256 amount, uint256 duration, , bool isJbToken) = _jbveBanny.getSpecs(1);
    assertEq(amount, 10 ether);
    assertEq(duration, 864000);
    assert(isJbToken);
  }

  function testUnlockingTokens() public {
    IJBToken _token = _jbTokenStore.tokenOf(_projectId);
    _projectOwner = projectOwner();
    evm.startPrank(_projectOwner);
    _jbController.mintTokensOf(_projectId, 100 ether, _projectOwner, 'Test Memo', true, true);
    _token.approve(_projectId, address(_jbveBanny), 100 ether);
    _jbveBanny.lock(_projectOwner, 10 ether, 864000, _projectOwner, true);
    (, , uint256 lockedUntil, ) = _jbveBanny.getSpecs(1);
    evm.warp(lockedUntil * 2);
    _jbveBanny.approve(address(_jbveBanny), 1);
    _jbveBanny.unlock(1, _projectOwner);
    assertEq(_token.balanceOf(address(_jbveBanny), _projectId), 0);
  }

  function testExtendLock() public {
    IJBToken _token = _jbTokenStore.tokenOf(_projectId);
    _projectOwner = projectOwner();
    evm.startPrank(_projectOwner);
    _jbController.mintTokensOf(_projectId, 100 ether, _projectOwner, 'Test Memo', true, true);
    _token.approve(_projectId, address(_jbveBanny), 100 ether);
    _jbveBanny.lock(_projectOwner, 10 ether, 864000, _projectOwner, true);
    (, uint256 d, uint256 lockedUntil, ) = _jbveBanny.getSpecs(1);
    assertEq(d, 864000);
    evm.warp(lockedUntil * 2);
    _jbveBanny.extendLock(1, 8640000);
    (, uint256 duration, , ) = _jbveBanny.getSpecs(1);
    assertEq(duration, 8640000);
  }
}
