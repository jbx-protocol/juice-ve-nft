// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
  @notice
  Global constants used across multiple Juicebox contracts.
*/
library JBConstants {
  /** 
    @notice
    Maximum value for reserved, redemption, and ballot redemption rates. Does not include discount rate.
  */
  uint256 public constant MAX_RESERVED_RATE = 10000;

  /**
    @notice
    Maximum token redemption rate.  
    */
  uint256 public constant MAX_REDEMPTION_RATE = 10000;

  /** 
    @notice
    A funding cycle's discount rate is expressed as a percentage out of 1000000000.
  */
  uint256 public constant MAX_DISCOUNT_RATE = 1000000000;

  /** 
    @notice
    Maximum splits percentage.
  */
  uint256 public constant SPLITS_TOTAL_PERCENT = 1000000000;

  /** 
    @notice
    Maximum fee rate as a percentage out of 1000000000
  */
  uint256 public constant MAX_FEE = 1000000000;

  /** 
    @notice
    Maximum discount on fee granted by a gauge.
  */
  uint256 public constant MAX_FEE_DISCOUNT = 1000000000;

  /** 
    @notice
    A thousand days in seconds, 60 seconds * 60 minutes * 24 hours * 1000 days.
  */
  uint256 public constant ONE_THOUSAND_DAYS = 8640000;

  /** 
    @notice
    Two hundred and fifty days in seconds, 60 seconds * 60 minutes * 24 hours * 250 days.
  */
  uint256 public constant TWO_HUNDRED_FIFTY_DAYS = 21600000;

  /** 
    @notice
    One hundred days in seconds, 60 seconds * 60 minutes * 24 hours * 100 days.
  */
  uint256 public constant ONE_HUNDRED_DAYS = 8640000;

  /** 
    @notice
    Twenty-five days in seconds, 60 seconds * 60 minutes * 24 hours * 25 days.
  */
  uint256 public constant TWENTY_FIVE_DAYS = 2160000;

  /** 
    @notice
    Ten days in seconds, 60 seconds * 60 minutes * 24 hours * 10 days.
  */
  uint256 public constant TEN_DAYS = 864000;
}
