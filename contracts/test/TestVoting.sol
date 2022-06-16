// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './helpers/TestBaseWorkflow.t.sol';
import '../veERC721.sol';
import '../interfaces/IJBVeTokenUriResolver.sol';

import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";

/**
@title JBVeNft Forge Tests
*/
contract JBVeNftTests is TestBaseWorkflow {
  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//
  JBVeNft private _jbveBanny;
  JBVeTokenUriResolver private _jbveTokenUriResolver;
  JBTokenStore private _jbTokenStore;
  JBController private _jbController;
  JBOperatorStore private _jbOperatorStore;
  address private _redemptionTerminal;
  uint256 private _projectId;
  address private _projectOwner;
  JBToken _paymentToken;

  uint256 public constant MAXTIME = 3 * 365 * 86400;

  //*********************************************************************//
  // --------------------------- test setup ---------------------------- //
  //*********************************************************************//
  /**
    @dev Setup the contract instances.
  */
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
    _lockDurationOptions[0] = 1 weeks;
    _lockDurationOptions[1] = 52 weeks;
    _lockDurationOptions[2] = 156 weeks;

    // JBVeNft
    _jbveBanny = new JBVeNft(
      _projectId,
      'Banny',
      'Banny',
      IJBVeTokenUriResolver(address(_jbveTokenUriResolver)),
      IJBTokenStore(address(_jbTokenStore)),
      IJBOperatorStore(address(_jbOperatorStore)),
      _lockDurationOptions,
      projectOwner()
    );
  }

  /**
    @dev Minting & Approving JBTokens.
  */
  function mintAndApproveIJBTokens() public returns (IJBToken) {
    IJBToken _jbToken = _jbTokenStore.tokenOf(_projectId);
    _projectOwner = projectOwner();
    vm.startPrank(_projectOwner);
    _jbController.mintTokensOf(_projectId, 100 ether, _projectOwner, 'Test Memo', true, true);
    _jbToken.approve(_projectId, address(_jbveBanny), 100 ether);
    vm.stopPrank();
    return _jbToken;
  }

  /**
    // TODO: This test seems to be returning an incorrect gas usage
    @dev Lock Test using a JBToken.
  */
  function testVotingGasUsage() public {
    mintAndApproveIJBTokens();

    vm.startPrank(_projectOwner);
    _jbveBanny.lock(_projectOwner, 10 ether, 156 weeks, _projectOwner, true, false);
    (int128 _amount, , uint256 _duration, bool _useJbToken, bool _allowPublicExtension) = _jbveBanny
      .locked(1);

    for(uint256 _i; _i < 4; _i++){
      // Mint a new banny
      uint256 _newId = _jbveBanny.lock(_projectOwner, 1 ether, 156 weeks, _projectOwner, true, false);

      // Forward 1 block
      vm.warp(block.timestamp + 15);
      vm.roll(block.number + 1);

      // Transfer the new banny
      _jbveBanny.transferFrom(_projectOwner, address(0xdead), _newId);
    }

    vm.stopPrank();

    address _tempHolder = address(0x1111);
    for(uint256 _i; _i < 4; _i++){
      // Mint a new banny
      vm.prank(_projectOwner);
      uint256 _newId = _jbveBanny.lock(_projectOwner, 1 ether, 156 weeks, _projectOwner, true, false);

      // Forward 1 block
      vm.warp(block.timestamp + 15);
      vm.roll(block.number + 1);

      // Transfer the new banny
      vm.prank(_projectOwner);
      _jbveBanny.transferFrom(_projectOwner, _tempHolder, _newId);

      // Forward 1 block
      vm.warp(block.timestamp + 15);
      vm.roll(block.number + 1);

      // Activate voting power for the temp holder
      vm.prank(_tempHolder);
      _jbveBanny.activateVotingPower(_newId);

      // Transfer it back
      vm.prank(_tempHolder);
      _jbveBanny.transferFrom(_tempHolder, _projectOwner, _newId);

      // Forward 1 block
      vm.warp(block.timestamp + 15);
      vm.roll(block.number + 1);

      // Activate voting power again
      vm.prank(_projectOwner);
      _jbveBanny.activateVotingPower(_newId);
    }


    // forward 152 weeks
    vm.warp(block.timestamp + 152 weeks);
    vm.roll(block.number + (152 weeks / 15));

    uint256 gasbefore = gasleft();
    uint256 _votingPowerOneToken = _jbveBanny.tokenVotingPowerAt(1, block.number);
    uint256 gasUsed = gasbefore - gasleft();

    //emit log_named_uint("Gas cost 'tokenVotingPowerAt'", gasUsed);

    gasbefore = gasleft();
    uint256 _votingPower = _jbveBanny.getVotes(_projectOwner);
    gasUsed = gasbefore - gasleft();

    //emit log_named_uint("Gas cost 'getVotes'", gasUsed);
  }
}
