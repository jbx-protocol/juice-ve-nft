// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBAllowPublicExtensionData {
  // The ID of the position.
  uint256 tokenId;
  // A flag indicating whether or not the lock can be extended publicly by anyone.
  bool allowPublicExtension;
}
