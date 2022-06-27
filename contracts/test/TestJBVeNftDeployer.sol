// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './helpers/TestBaseWorkflow.t.sol';
import '../interfaces/IJBVeTokenUriResolver.sol';

contract JBVeNftDeployerTests is TestBaseWorkflow {
  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//
  IJBVeNft private _jbveBanny;
  JBVeTokenUriResolver private _jbveTokenUriResolver;
  JBVeNftDeployer private _jbveNftDeployer;
  JBProjects private _jbProjects;
  JBTokenStore private _jbTokenStore;
  JBOperatorStore private _jbOperatorStore;
  uint256 private _projectId;
  uint256[] _lockDurationOptions = new uint256[](3);

  //*********************************************************************//
  // --------------------------- test setup ---------------------------- //
  //*********************************************************************//
  function setUp() public override {
    // calling before each for TestBaseWorkflow
    super.setUp();
    // fetching instances deployed in the base workflow file
    _jbProjects = jbProjects();
    _jbOperatorStore = jbOperatorStore();

    _jbveNftDeployer = new JBVeNftDeployer(
      IJBProjects(_jbProjects),
      IJBOperatorStore(address(_jbOperatorStore))
    );
  }

  function testConstructor() public {
    // assertion checks for constructor code
    assertEq(address(_jbProjects), address(_jbveNftDeployer.projects()));
  }

  function testDeployVeNFT() public {
    _projectId = projectID();
    _jbTokenStore = jbTokenStore();
    _jbveTokenUriResolver = jbveTokenUriResolver();

    // lock duration options array to be used for mock deployment
    // All have to be dividable by weeks
    _lockDurationOptions[0] = 1 weeks; // 1 week
    _lockDurationOptions[1] = 4 weeks; // 4 weeks
    _lockDurationOptions[2] = 12 weeks; // 12 weeks

    vm.startPrank(projectOwner());

    _jbveBanny = _jbveNftDeployer.deployVeNFT(
      _projectId,
      'Banny',
      'Banny',
      IJBVeTokenUriResolver(address(_jbveTokenUriResolver)),
      IJBTokenStore(address(_jbTokenStore)),
      IJBOperatorStore(address(_jbOperatorStore)),
      _lockDurationOptions,
      projectOwner()
    );

    assertEq(address(_jbveTokenUriResolver), address(_jbveBanny.uriResolver()));
    assertEq(_projectId, _jbveBanny.projectId());
    assertEq(_lockDurationOptions[0], _jbveBanny.lockDurationOptions()[0]);

    vm.stopPrank();
  }

  function testScenarioWithInvalidDeployer() public {
    _projectId = projectID();
    _jbTokenStore = jbTokenStore();
    _jbveTokenUriResolver = jbveTokenUriResolver();

    // lock duration options array to be used for mock deployment
    // All have to be dividable by weeks
    _lockDurationOptions[0] = 1 weeks; // 1 week
    _lockDurationOptions[1] = 4 weeks; // 4 weeks
    _lockDurationOptions[2] = 12 weeks; // 12 weeks

    vm.expectRevert(abi.encodeWithSignature('UNAUTHORIZED()'));
    _jbveBanny = _jbveNftDeployer.deployVeNFT(
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
}
