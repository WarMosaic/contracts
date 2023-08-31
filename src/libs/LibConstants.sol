// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

library LibConstants {
  /**
   * @dev Percentage of the tile cost and trading price that goes to the project.
   */
  bytes32 internal constant PROJECT_FEE_BIPS = keccak256("project.fee.bips");
  /**
   * @dev Percentage of the tile cost and trading price that goes to the game creator.
   */
  bytes32 internal constant GAME_CREATOR_FEE_BIPS = keccak256("creator.fee.bips");
  /**
   * @dev Percentage of the tile cost and trading price that goes to the referer.
   */
  bytes32 internal constant REFERER_FEE_BIPS = keccak256("referer.fee.bips");
  /**
   * @dev Percentage of the tile cost and trading price that goes to the staking pool.
   */
  bytes32 internal constant STAKING_FEE_BIPS = keccak256("liquidity.fee.bips");
  /**
   * @dev Address of MOSAIC token.
   */
  bytes32 internal constant MOSAIC_TOKEN = keccak256("mosaic.token");
  /**
   * @dev Address of authorizing signatory (usually the server).
   */
  bytes32 internal constant AUTHORIZED_SIGNER = keccak256("authorized.signer");
}
