// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import 'forge-std/Test.sol';

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBTokenStore.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBOperatorStore.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBProjects.sol';

import '../contracts/interfaces/IJBVeNft.sol';
import '../contracts/interfaces/IJBVeTokenUriResolver.sol';

import '../contracts/JBVeNftDeployer.sol';
import '../contracts/JBVeTokenUriResolver.sol';

contract Deploy is Test {

    IJBVeNft jbVeNft;
    JBVeTokenUriResolver jbVeTokenUriResolver;
    JBVeNftDeployer jbVeNftDeployer;


    IJBTokenStore tokenStore = IJBTokenStore(0xa2C08C071514c46671d675553453755bEf8E95bB);
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
      msg.sender
    );
    
    vm.stopBroadcast();
   }
}