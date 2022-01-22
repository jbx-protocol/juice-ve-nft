// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';

/**
  @notice
  Allows JBX Holders to stake their tokens and receive Jbx Banny based ont heir stake and lock in period.
  @dev 
  Bannies are transferrable, will be burnt when the stake is claimed before or after the lock-in period ends.
  The Token URI will be determined by SVG for each banny category.
  Inherits from:
  ERC1155 - for ERC1155 support.
  ERC1155Burnable - for burning the bannies.
*/
contract JBBanny is ERC1155, ERC1155Burnable {
  /** 
    @notice 
    JBX Token Instance
    */
  IERC20 public immutable jbx;

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//
  /**
    @param _jbx jbx address.
    @dev uri is empty since we will have svg support
  */
  constructor(IERC20 _jbx) ERC1155('') {
    jbx = _jbx;
  }

  /**
   * @dev Computes the metadata url based on the id.
     @return dynamic uri based on the svg logic for that particular banny
  */
  function tokenURI() public view returns (string memory) {
    // svg logic where based on user stake we render the nft
  }
}
