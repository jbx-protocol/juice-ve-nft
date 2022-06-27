// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBProjects.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBTokenStore.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBOperatorStore.sol';
import './IJBVeTokenUriResolver.sol';
import './IJBVeNft.sol';

interface IJBVeNftDeployer {
  event DeployVeNft(
    address jbVeNft,
    uint256 indexed projectId,
    string name,
    string symbol,
    IJBVeTokenUriResolver uriResolver,
    IJBTokenStore tokenStore,
    IJBOperatorStore operatorStore,
    uint256[] lockDurationOptions,
    address owner,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function deployVeNFT(
    uint256 _projectId,
    string memory _name,
    string memory _symbol,
    IJBVeTokenUriResolver _uriResolver,
    IJBTokenStore _tokenStore,
    IJBOperatorStore _operatorStore,
    uint256[] memory _lockDurationOptions,
    address _owner
  ) external returns (IJBVeNft veNft);
}
