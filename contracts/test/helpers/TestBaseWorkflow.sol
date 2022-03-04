// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './DSTest.sol';
import './hevm.sol';
import '../../JBveBanny.sol';
import '../../JBVeTokenUriResolver.sol';

import '@jbx-protocol/contracts-v2/contracts/JBDirectory.sol';
import '@jbx-protocol/contracts-v2/contracts/JBOperatorStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBProjects.sol';
import '@jbx-protocol/contracts-v2/contracts/JBTokenStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBFundingCycleStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBSplitsStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBController.sol';

// Base contract for Juicebox system tests.
//
// Provides common functionality, such as deploying contracts on test setup.
abstract contract TestBaseWorkflow is DSTest {
  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//

  // Multisig address used for testing.
  address private _multisig = address(123);

  // EVM Cheat codes - test addresses via prank and startPrank in hevm
  Hevm public evm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  // JBOperatorStore
  JBOperatorStore private _jbOperatorStore;
  // JBProjects
  JBProjects private _jbProjects;
  // JBDirectory
  JBDirectory private _jbDirectory;
  // JBFundingCycleStore
  JBFundingCycleStore private _jbFundingCycleStore;
  // JBTokenStore
  JBTokenStore private _jbTokenStore;
  // JBSplitsStore
  JBSplitsStore private _jbSplitsStore;
  // JBController
  JBController private _jbController;
  // JBveBanny
  JBveBanny private _jbveBanny;
  // JBVeTokenUriResolver
  JBVeTokenUriResolver private _jbveTokenUriResolver;

  //*********************************************************************//
  // ------------------------- internal views -------------------------- //
  //*********************************************************************//

  function multisig() internal view returns (address) {
    return _multisig;
  }

  function jbOperatorStore() internal view returns (JBOperatorStore) {
    return _jbOperatorStore;
  }

  function jbProjects() internal view returns (JBProjects) {
    return _jbProjects;
  }

  function jbDirectory() internal view returns (JBDirectory) {
    return _jbDirectory;
  }

  function jbFundingCycleStore() internal view returns (JBFundingCycleStore) {
    return _jbFundingCycleStore;
  }

  function jbTokenStore() internal view returns (JBTokenStore) {
    return _jbTokenStore;
  }

  function jbSplitsStore() internal view returns (JBSplitsStore) {
    return _jbSplitsStore;
  }

  function jbController() internal view returns (JBController) {
    return _jbController;
  }

  function jbveBanny() internal view returns (JBveBanny) {
    return _jbveBanny;
  }

  function jbveTokenUriResolver() internal view returns (JBVeTokenUriResolver) {
    return _jbveTokenUriResolver;
  }

  //*********************************************************************//
  // --------------------------- test setup ---------------------------- //
  //*********************************************************************//

  // Deploys and initializes contracts for testing.
  function setUp() public virtual {
    // JBOperatorStore
    _jbOperatorStore = new JBOperatorStore();
    // JBProjects
    _jbProjects = new JBProjects(_jbOperatorStore);
    // JBDirectory
    _jbDirectory = new JBDirectory(_jbOperatorStore, _jbProjects);
    // JBTokenStore
    _jbTokenStore = new JBTokenStore(_jbOperatorStore, _jbProjects, _jbDirectory);
    // JBVeTokenUriResolver
    _jbveTokenUriResolver = new JBVeTokenUriResolver();
  }
}