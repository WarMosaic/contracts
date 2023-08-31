// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";

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
    if (g.i.state != state) {
      revert GameInWrongState(g.i.id);
    }
  }

  function assertGameNotEndedOrCancelled(Game storage g) internal view {
    if (g.i.state == GameState.Ended || g.i.state == GameState.Cancelled) {
      revert GameInWrongState(g.i.id);
    }
  }

  function assertGameTileId(Game storage g, uint tileId) internal view {
    if (tileId < 1 || tileId > g.i.cfg.numTiles) {
      revert InvalidGameTile(g.i.id, tileId);
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
}
