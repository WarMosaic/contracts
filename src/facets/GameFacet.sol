// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibGame } from "../libs/LibGame.sol";
import { MetaContext } from "../shared/MetaContext.sol";

error GameInvalidNumTiles(uint numTiles);
error GameInvalidMaxTilesPerPlayer(uint maxTilesPerPlayer);
error GameInvalidTileCost(uint tileCost);
error GameTileAlreadyOwned(uint gameId, uint tileId);
error GameMaxTilesPerPlayerReached(uint gameId, address player);
error InsufficientFundsToJoinGame(uint amount);

contract GameFacet is MetaContext {  
  event GameCreated(address creator, uint gameId);
  event GameJoined(uint gameId, uint tileId, address player);

  function createGame(GameCreationConfig memory cfg) external {
    if (cfg.numTiles == 0 || cfg.numTiles > 1024 || cfg.numTiles % 4 != 0) {
      revert GameInvalidNumTiles(cfg.numTiles);
    }

    if (cfg.tileCost < 0.01 ether) {
      revert GameInvalidTileCost(cfg.tileCost);
    }

    if (cfg.maxTilesPerPlayer < 1 || cfg.maxTilesPerPlayer > cfg.numTiles) {
      revert GameInvalidMaxTilesPerPlayer(cfg.maxTilesPerPlayer);
    }

    AppStorage storage s = LibAppStorage.diamondStorage();
    s.numGames++;
    Game storage g = s.games[s.numGames];

    g.i.id = s.numGames;
    g.i.creator = _msgSender();
    g.i.cfg = cfg;
    g.i.state = GameState.AwaitingPlayers;
    g.i.lastUpdated = block.timestamp;

    emit GameCreated(g.i.creator, s.numGames);
  }

  function joinGame(uint gameId, uint tileId) external payable {
    (AppStorage storage s, Game storage g, Tile storage t) = LibGame.loadGameTile(gameId, tileId);

    address player = _msgSender();

    LibGame.assertGameState(g, GameState.AwaitingPlayers);

    if (t.owner != address(0)) {
      revert GameTileAlreadyOwned(gameId, tileId);
    }

    if (g.numTilesOwnedBy[player] == g.i.cfg.maxTilesPerPlayer) {
      revert GameMaxTilesPerPlayerReached(gameId, player);
    }

    if (msg.value < g.i.cfg.tileCost) {
      revert InsufficientFundsToJoinGame(msg.value);
    }

    g.i.numTilesOwned++;
    g.tiles[tileId] = Tile({
      id: tileId,
      pot: msg.value,
      owner: player,
      potClaimed: false
    });
    g.numTilesOwnedBy[player]++;
    g.tileOwnedByIndex[player][g.numTilesOwnedBy[player]] = tileId;

    if (g.i.numTilesOwned == g.i.cfg.numTiles) {
      g.i.state = GameState.Started;
    }

    g.i.lastUpdated = block.timestamp;

    emit GameJoined(gameId, tileId, player);
  }

  /**
   * @dev Anyone can cancel game if it has been inactive for too long.
   */
  function cancelGame(uint gameId) external {
    (AppStorage storage s, Game storage g) = LibGame.loadGame(gameId);

    LibGame.assertGameNotEndedOrCancelled(g);

    if (g.i.lastUpdated + 30 days < block.timestamp) {
      g.i.state = GameState.Cancelled;
      g.i.lastUpdated = block.timestamp;
    }
  }

  // Getters

  function getGameNonMappingInfo(uint gameId) external view returns (GameNonMappingInfo memory) {
    return LibAppStorage.diamondStorage().games[gameId].i;
  }

  function getGameTile(uint gameId, uint tileId) external view returns (Tile memory) {
    return LibAppStorage.diamondStorage().games[gameId].tiles[tileId];
  }

  function getGameNumTilesOwnedByWallet(uint gameId, address owner) external view returns (uint) {
    return LibAppStorage.diamondStorage().games[gameId].numTilesOwnedBy[owner];
  }

  function getIdOfGameTileOwnedByWalletAtIndex(uint gameId, address owner, uint index) external view returns (uint) {
    return LibAppStorage.diamondStorage().games[gameId].tileOwnedByIndex[owner][index];
  }
}
