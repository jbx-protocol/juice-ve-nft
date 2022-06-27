// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBVeNft.sol';
import './interfaces/IJBVeNftDeployer.sol';

/**
  @notice
  Allows a project owner to deploy a veNFT contract.
*/
contract JBVeNftDeployer is IJBVeNftDeployer, JBOperatable {
  /**
    @notice
    Mints ERC-721's that represent project ownership.
  */
  IJBProjects public immutable override projects;

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//

  /**
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(IJBProjects _projects, IJBOperatorStore _operatorStore) JBOperatable(_operatorStore) {
    projects = _projects;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Allows anyone to deploy a new project payer contract.

    @param _projectId The ID of the project.
    @param _name Nft name.
    @param _symbol Nft symbol.
    @param _uriResolver Token uri resolver instance.
    @param _tokenStore The JBTokenStore where unclaimed tokens are accounted for.
    @param _lockDurationOptions The lock options, in seconds, for lock durations.
    @param _owner The address that will own the staking contract.

    @return veNft The ve NFT contract that was deployed.
  */
  function deployVeNFT(
    uint256 _projectId,
    string memory _name,
    string memory _symbol,
    IJBVeTokenUriResolver _uriResolver,
    IJBTokenStore _tokenStore,
    IJBOperatorStore _operatorStore,
    uint256[] memory _lockDurationOptions,
    address _owner
  )
    external
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBStakingOperations.DEPLOY_VE_NFT)
    returns (IJBVeNft veNft)
  {
    // Deploy the ve nft contract.
    veNft = new JBVeNft(
      _projectId,
      _name,
      _symbol,
      _uriResolver,
      _tokenStore,
      _operatorStore,
      _lockDurationOptions,
      _owner
    );

    emit DeployVeNft(
      address(veNft),
      _projectId,
      _name,
      _symbol,
      _uriResolver,
      _tokenStore,
      _operatorStore,
      _lockDurationOptions,
      _owner,
      msg.sender
    );
  }
}
