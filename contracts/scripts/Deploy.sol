// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import 'forge-std/Test.sol';

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBTokenStore.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBOperatorStore.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBProjects.sol';

import '../interfaces/IJBVeNft.sol';
import '../interfaces/IJBVeTokenUriResolver.sol';

import '../JBVeNftDeployer.sol';
import '../JBVeTokenUriResolver.sol';

contract DeployRinkeby is Test {

    IJBVeNft jbVeNft;
    JBVeTokenUriResolver jbVeTokenUriResolver;
    JBVeNftDeployer jbVeNftDeployer;

    
    IJBTokenStore tokenStore = IJBTokenStore(0x220468762c6cE4C05E8fda5cc68Ffaf0CC0B2A85);
    IJBOperatorStore operatorStore = IJBOperatorStore(0xEDB2db4b82A4D4956C3B4aA474F7ddf3Ac73c5AB);
    IJBProjects projects = IJBProjects(0x2d8e361f8F1B5daF33fDb2C99971b33503E60EEE);

    address multisig = 0x69C6026e3938adE9e1ddE8Ff6A37eC96595bF1e1;

    function run() public {
    vm.startBroadcast();

    jbVeTokenUriResolver = new JBVeTokenUriResolver();

    jbVeNftDeployer = new JBVeNftDeployer(
        projects,
        operatorStore
    );

    uint256[] memory _lockDurationOptions = new uint256[](3);
    _lockDurationOptions[0] = 1 weeks;
    _lockDurationOptions[1] = 4 weeks;
    _lockDurationOptions[2] = 12 weeks;

    jbVeNft = jbVeNftDeployer.deployVeNFT(
       1,
      'Banny',
      'Banny',
      IJBVeTokenUriResolver(address(jbVeTokenUriResolver)),
      tokenStore,
      operatorStore,
      _lockDurationOptions,
      multisig
    );
    
    vm.stopBroadcast();
   }
}

contract DeployMainnet is Test {

    IJBVeNft jbVeNft;
    JBVeTokenUriResolver jbVeTokenUriResolver;
    JBVeNftDeployer jbVeNftDeployer;

    
    IJBTokenStore tokenStore = IJBTokenStore(0xCBB8e16d998161AdB20465830107ca298995f371);
    IJBOperatorStore operatorStore = IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);
    IJBProjects projects = IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);

    address multisig = 0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e;

    function run() public {
    vm.startBroadcast();

    jbVeTokenUriResolver = new JBVeTokenUriResolver();

    jbVeNftDeployer = new JBVeNftDeployer(
        projects,
        operatorStore
    );

    uint256[] memory _lockDurationOptions = new uint256[](3);
    _lockDurationOptions[0] = 1 weeks;
    _lockDurationOptions[1] = 4 weeks;
    _lockDurationOptions[2] = 12 weeks;

    jbVeNft = jbVeNftDeployer.deployVeNFT(
       1,
      'Banny',
      'Banny',
      IJBVeTokenUriResolver(address(jbVeTokenUriResolver)),
      tokenStore,
      operatorStore,
      _lockDurationOptions,
      multisig
    );
    
    vm.stopBroadcast();
   }
}