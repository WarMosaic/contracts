// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

library LibConstants {
  /**
   * @dev Percentage of the tile cost that goes to the project.
   */
  bytes32 internal constant JOINING_PROJECT_FEE_BIPS = keccak256("project.fee.bips");
  /**
   * @dev Percentage of the tile cost that goes to the game creator.
   */
  bytes32 internal constant JOINING_GAME_CREATOR_FEE_BIPS = keccak256("creator.fee.bips");
  /**
   * @dev Percentage of the tile cost that goes to the referer.
   */
  bytes32 internal constant JOINING_REFERER_FEE_BIPS = keccak256("referer.fee.bips");
  /**
   * @dev Percentage of the trading price that goes to the project.
   */
  bytes32 internal constant TRADING_PROJECT_FEE_BIPS = keccak256("project.fee.bips");
  /**
   * @dev Percentage of the trading price that goes to the game creator.
   */
  bytes32 internal constant TRADING_GAME_CREATOR_FEE_BIPS = keccak256("creator.fee.bips");
  /**
   * @dev Percentage of the trading price that goes to the referer.
   */
  bytes32 internal constant TRADING_REFERER_FEE_BIPS = keccak256("referer.fee.bips");
  /**
   * @dev Address of MOSAIC token.
   */
  bytes32 internal constant MOSAIC_TOKEN = keccak256("mosaic.token");
  /**
   * @dev Address of project wallet.
   */
  bytes32 internal constant PROJECT_WALLET = keccak256("project.wallet");
  /**
   * @dev Address of authorizing signatory wallet (usually the server).
   */
  bytes32 internal constant AUTHORIZED_SIGNER_WALLET = keccak256("authorized.signer.wallet");
}
