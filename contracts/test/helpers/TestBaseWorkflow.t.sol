// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '../../JBVeNft.sol';
import '../../JBVeTokenUriResolver.sol';
import './AccessJBLib.sol';
import 'forge-std/Test.sol';

import '@jbx-protocol/contracts-v2/contracts/JBDirectory.sol';
import '@jbx-protocol/contracts-v2/contracts/JBSingleTokenPaymentTerminalStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBOperatorStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBPrices.sol';
import '@jbx-protocol/contracts-v2/contracts/JBProjects.sol';
import '@jbx-protocol/contracts-v2/contracts/JBTokenStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBFundingCycleStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBSplitsStore.sol';
import '@jbx-protocol/contracts-v2/contracts/JBController.sol';
import '@jbx-protocol/contracts-v2/contracts/JBToken.sol';
import '@jbx-protocol/contracts-v2/contracts/JBERC20PaymentTerminal.sol';

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

import '@jbx-protocol/contracts-v2/contracts/libraries/JBCurrencies.sol';

// Base contract for JBX Banny system tests.
//
// Provides common functionality, such as deploying contracts on test setup.
abstract contract TestBaseWorkflow is Test {
  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//

  // Multisig address used for testing.
  address private _multisig = address(123);

  // JBOperatorStore
  JBOperatorStore private _jbOperatorStore;
  // JBProjects
  JBProjects private _jbProjects;
  // JBPrices
  JBPrices private _jbPrices;
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
  // JBETHPaymentTerminalStore
  JBSingleTokenPaymentTerminalStore private _jbPaymentTerminalStore;
  // JBERC20PaymentTerminal
  JBERC20PaymentTerminal private _jbERC20PaymentTerminal;
  // JBToken
  JBToken private _paymentToken;
  // IJBTerminal
  IJBPaymentTerminal[] private _terminals;
  // AccessJBLib
  AccessJBLib private _accessJBLib;

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

  function jbPaymentTerminalStore() internal view returns (JBSingleTokenPaymentTerminalStore) {
    return _jbPaymentTerminalStore;
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

  function jbERC20PaymentTerminal() internal view returns (address) {
    return address(_jbERC20PaymentTerminal);
  }

  function jbToken() internal view returns (JBToken) {
    return _paymentToken;
  }

  //*********************************************************************//
  // --------------------------- test setup ---------------------------- //
  //*********************************************************************//

  // Deploys and initializes contracts for testing.
  function setUp() public virtual {
    _projectOwner = multisig();
    // JBOperatorStore
    _jbOperatorStore = new JBOperatorStore();
    // JBProjects
    _jbProjects = new JBProjects(_jbOperatorStore);
    // JBPrices
    _jbPrices = new JBPrices(_multisig);
    // JBFundingCycleStore
    address contractAtNoncePlusOne = addressFrom(address(this), 5);
    _jbFundingCycleStore = new JBFundingCycleStore(IJBDirectory(contractAtNoncePlusOne));
    // JBDirectory
    _jbDirectory = new JBDirectory(
      _jbOperatorStore,
      _jbProjects,
      _jbFundingCycleStore,
      _projectOwner
    );
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

    _jbPaymentTerminalStore = new JBSingleTokenPaymentTerminalStore(
      _jbDirectory,
      _jbFundingCycleStore,
      _jbPrices
    );

    vm.prank(_multisig);
    _paymentToken = new JBToken('MyToken', 'MT');
    vm.prank(_multisig);
    _paymentToken.mint(0, _multisig, 100 ether);

    // AccessJBLib
    _accessJBLib = new AccessJBLib();

    _jbERC20PaymentTerminal = new JBERC20PaymentTerminal(
      _paymentToken,
      _accessJBLib.ETH(), // currency
      _accessJBLib.ETH(), // base weight currency
      1, // JBSplitsGroupe
      _jbOperatorStore,
      _jbProjects,
      _jbDirectory,
      _jbSplitsStore,
      _jbPrices,
      _jbPaymentTerminalStore,
      _multisig
    );

    vm.startPrank(_projectOwner);

    _fundAccessConstraints.push(
      JBFundAccessConstraints({
        terminal: _jbERC20PaymentTerminal,
        token: address(_paymentToken),
        distributionLimit: 10 * 10**18,
        overflowAllowance: 5 * 10**18,
        distributionLimitCurrency: _accessJBLib.ETH(),
        overflowAllowanceCurrency: _accessJBLib.ETH()
      })
    );
    _jbDirectory.setIsAllowedToSetFirstController(address(_jbController), true);

    _terminals.push(_jbERC20PaymentTerminal);

    vm.stopPrank();
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
      redemptionRate: 10000,
      ballotRedemptionRate: 0,
      pausePay: false,
      pauseDistributions: false,
      pauseRedeem: false,
      pauseBurn: false,
      allowMinting: true,
      allowChangeToken: true,
      allowTerminalMigration: false,
      allowControllerMigration: false,
      allowSetTerminals: false,
      allowSetController: false,
      holdFees: false,
      useTotalOverflowForRedemptions: true,
      useDataSourceForPay: false,
      useDataSourceForRedeem: false,
      dataSource: IJBFundingCycleDataSource(address(0))
    });

    _projectId = _jbController.launchProjectFor(
      _projectOwner,
      _projectMetadata,
      _data,
      _metadata,
      block.timestamp,
      _groupedSplits,
      _fundAccessConstraints,
      _terminals,
      ''
    );

    // calls will originate from projectOwner addr
    vm.startPrank(_projectOwner);
    // issue an ERC-20 token for project
    _jbController.issueTokenFor(_projectId, 'TestName', 'TestSymbol');
    vm.stopPrank();
  }

  //https://ethereum.stackexchange.com/questions/24248/how-to-calculate-an-ethereum-contracts-address-during-its-creation-using-the-so
  function addressFrom(address _origin, uint256 _nonce) internal pure returns (address _address) {
    bytes memory data;
    if (_nonce == 0x00) data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80));
    else if (_nonce <= 0x7f)
      data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce));
    else if (_nonce <= 0xff)
      data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce));
    else if (_nonce <= 0xffff)
      data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce));
    else if (_nonce <= 0xffffff)
      data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce));
    else data = abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce));
    bytes32 hash = keccak256(data);
    assembly {
      mstore(0, hash)
      _address := mload(0)
    }
  }
}
