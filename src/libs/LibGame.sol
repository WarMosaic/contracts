// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { LibSettings } from "./LibSettings.sol";

error InvalidGame(uint gameId);
error InvalidGameTile(uint gameId, uint tileId);
error GameInWrongState(uint gameId);

library LibGame {
  function assertGameId(AppStorage storage s, uint gameId) internal view {
    if (gameId < 1 || gameId > s.numGames) {
      revert InvalidGame(gameId);
    }
  }

  function assertGameState(Game storage g, GameState state) internal view {
    if (g.state != state) {
      revert GameInWrongState(g.id);
    }
  }

  function assertGameNotEndedOrCancelled(Game storage g) internal view {
    if (g.state == GameState.Ended || g.state == GameState.Cancelled) {
      revert GameInWrongState(g.id);
    }
  }

  function assertGameTileId(Game storage g, uint tileId) internal view {
    if (tileId < 1 || tileId > g.cfg.numTiles) {
      revert InvalidGameTile(g.id, tileId);
    }
  }

  function loadGame(uint gameId) internal view returns (AppStorage storage s, Game storage game) {
    s = LibAppStorage.diamondStorage();
    assertGameId(s, gameId);
    game = s.games[gameId];
  }

  function loadGameTile(uint gameId, uint tileId) internal view returns (AppStorage storage s, Game storage game, Tile storage tile) {
    (s, game) = loadGame(gameId);
    assertGameTileId(game, tileId);
    tile = game.tiles[tileId];
  }

  function updateTileOnwer(Tile storage t, address newOwner) internal {
    t.owner = newOwner;
  }

  function updateQuadStatus(AppStorage storage s, Game storage g, Tile storage t) internal {

  }

  function calculateAndApplyFees(uint amount, address creator, address referer) internal returns (uint amountMinusFees, uint totalFees) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    Settings storage settings = s.settings;

    uint creatorFeeAmount = (amount * LibSettings.getGameCreatorFeeBips()) / 10000;
    uint refererFeeAmount = (amount * LibSettings.getRefererFeeBips()) / 10000;
    uint projectFeeAmount = (amount * LibSettings.getProjectFeeBips()) / 10000;
    totalFees = creatorFeeAmount + refererFeeAmount + projectFeeAmount;
    amountMinusFees = amount - totalFees;

    address projectWallet = LibSettings.getProjectWallet();

    if (referer != address(0)) {
      s.users[creator].balance += creatorFeeAmount;
    } else {
      s.users[projectWallet].balance += creatorFeeAmount;
    }

    if (referer != address(0)) {
      s.users[referer].balance += refererFeeAmount;
    } else {
      s.users[projectWallet].balance += refererFeeAmount;
    }

    s.users[projectWallet].balance += projectFeeAmount;
  }
}
