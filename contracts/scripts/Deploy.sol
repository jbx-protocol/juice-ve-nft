// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import 'forge-std/Test.sol';

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBOperatorStore.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBProjects.sol';

import '../JBVeNftDeployer.sol';

contract DeployRinkeby is Test {
  JBVeNftDeployer jbVeNftDeployer;

  IJBOperatorStore operatorStore = IJBOperatorStore(0xEDB2db4b82A4D4956C3B4aA474F7ddf3Ac73c5AB);
  IJBProjects projects = IJBProjects(0x2d8e361f8F1B5daF33fDb2C99971b33503E60EEE);

  function run() public {
    vm.startBroadcast();

    jbVeNftDeployer = new JBVeNftDeployer(projects, operatorStore);

    vm.stopBroadcast();
  }
}

contract DeployMainnet is Test {
  JBVeNftDeployer jbVeNftDeployer;

  IJBOperatorStore operatorStore = IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);
  IJBProjects projects = IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);

  function run() public {
    vm.startBroadcast();

    jbVeNftDeployer = new JBVeNftDeployer(projects, operatorStore);

    vm.stopBroadcast();
  }
}
