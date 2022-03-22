// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './DSTest.t.sol';
import './hevm.t.sol';
import '../../JBveBanny.sol';
import '../../JBVeTokenUriResolver.sol';

import '@jbx-protocol/contracts-v2/contracts/JBDirectory.sol';
import '@jbx-protocol/contracts-v2/contracts/JBOperatorStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBProjects.sol';
import '@jbx-protocol/contracts-v2/contracts/JBTokenStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBFundingCycleStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBSplitsStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBController.sol';
import '@jbx-protocol/contracts-v2/contracts/JBToken.sol';

import '@jbx-protocol/contracts-v2/contracts/structs/JBProjectMetadata.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundingCycleData.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundingCycleMetadata.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBGroupedSplits.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBFundAccessConstraints.sol';
import '@jbx-protocol/contracts-v2/contracts/structs/JBOperatorData.sol';

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBPaymentTerminal.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBToken.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBTokenStore.sol';
import '@jbx-protocol/contracts-v2/contracts/abstract/JBOperatable.sol';

// Base contract for JBX Banny system tests.
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
  // JBVeTokenUriResolver
  JBVeTokenUriResolver private _jbveTokenUriResolver;
  // JBProjectMetadata
  JBProjectMetadata private _projectMetadata;
  // JBFundingCycleData
  JBFundingCycleData private _data;
  // JBFundingCycleMetadata
  JBFundingCycleMetadata private _metadata;
  // JBGroupedSplits
  JBGroupedSplits[] private _groupedSplits;
  // JBFundAccessConstraints
  JBFundAccessConstraints[] private _fundAccessConstraints;
  // IJBTerminal
  IJBPaymentTerminal[] private _terminals;

  uint256 private _projectId;
  address private _projectOwner;
  uint256 private _reservedRate = 5000;


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

  function jbveTokenUriResolver() internal view returns (JBVeTokenUriResolver) {
    return _jbveTokenUriResolver;
  }

  function projectID() internal view returns (uint256) {
    return _projectId;
  }

  function projectOwner() internal view returns (address) {
    return _projectOwner;
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
    // JBFundingCycleStore
    _jbFundingCycleStore = new JBFundingCycleStore(_jbDirectory);
    // JBTokenStore
    _jbTokenStore = new JBTokenStore(_jbOperatorStore, _jbProjects, _jbDirectory);
    // JBSplitsStore
    _jbSplitsStore = new JBSplitsStore(_jbOperatorStore, _jbProjects, _jbDirectory);
    // JBController
    _jbController = new JBController(
      _jbOperatorStore,
      _jbProjects,
      _jbDirectory,
      _jbFundingCycleStore,
      _jbTokenStore,
      _jbSplitsStore
    );
    _jbDirectory.addToSetControllerAllowlist(address(_jbController));
    // JBVeTokenUriResolver
    _jbveTokenUriResolver = new JBVeTokenUriResolver();

    // issuing token to be used for banny tests
    _projectMetadata = JBProjectMetadata({content: 'myIPFSHash', domain: 1});

    _data = JBFundingCycleData({
      duration: 14,
      weight: 1000 * 10**18,
      discountRate: 450000000,
      ballot: IJBFundingCycleBallot(address(0))
    });

    _metadata = JBFundingCycleMetadata({
      reservedRate: _reservedRate,
      redemptionRate: 5000,
      ballotRedemptionRate: 0,
      pausePay: false,
      pauseDistributions: false,
      pauseRedeem: false,
      pauseMint: false,
      pauseBurn: false,
      allowChangeToken: true,
      allowTerminalMigration: false,
      allowControllerMigration: false,
      holdFees: false,
      useLocalBalanceForRedemptions: false,
      useDataSourceForPay: false,
      useDataSourceForRedeem: false,
      dataSource: IJBFundingCycleDataSource(address(0))
    });

    _projectOwner = multisig();

    _projectId = _jbController.launchProjectFor(
      _projectOwner,
      _projectMetadata,
      _data,
      _metadata,
      block.timestamp,
      _groupedSplits,
      _fundAccessConstraints,
      _terminals
    );

    // calls will originate from projectOwner addr
    evm.startPrank(_projectOwner);
    // issue an ERC-20 token for project
    _jbController.issueTokenFor(_projectId, 'TestName', 'TestSymbol');
  }
}