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

  function createGame(GameConfig memory cfg) external {
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

    g.id = s.numGames;
    g.creator = _msgSender();
    g.cfg = cfg;
    g.state = GameState.AwaitingPlayers;
    g.lastUpdated = block.timestamp;

    emit GameCreated(g.creator, s.numGames);
  }

  function joinGame(uint gameId, uint tileId, uint referralCode) external payable {
    (AppStorage storage s, Game storage g, Tile storage t) = LibGame.loadGameTile(gameId, tileId);

    address player = _msgSender();

    LibGame.assertGameState(g, GameState.AwaitingPlayers);

    if (t.owner != address(0)) {
      revert GameTileAlreadyOwned(gameId, tileId);
    }

    if (g.players[player].numTilesOwned == g.cfg.maxTilesPerPlayer) {
      revert GameMaxTilesPerPlayerReached(gameId, player);
    }

    if (msg.value < g.cfg.tileCost) {
      revert InsufficientFundsToJoinGame(msg.value);
    }

    // tile id
    GamePlayer storage gp = g.players[player];
    gp.numTilesOwned++;
    gp.tilesByIndex[gp.numTilesOwned] = tileId;

    // if this is the first tile then set the referer and referral code
    // for subsequent tiles, it will use the already saved referer, thus preventing a player from using their own referral code
    if (gp.numTilesOwned == 1) {
      gp.referer = g.playersByReferralCode[referralCode];
      gp.referralCode = uint(keccak256(abi.encodePacked(player, _msgData(), g.lastUpdated))) % 10000;
      g.playersByReferralCode[referralCode] = player;
    }

    // apply fees
    (uint finalAmount, ) = LibGame.calculateAndApplyFees(msg.value, g.creator, gp.referer);

    g.numTilesOwned++;
    g.tiles[tileId] = Tile({
      id: tileId,
      pot: finalAmount,
      owner: player,
      potClaimed: false
    });

    if (g.numTilesOwned == g.cfg.numTiles) {
      g.state = GameState.Started;
    }

    g.lastUpdated = block.timestamp;

    emit GameJoined(gameId, tileId, player);
  }

  /**
   * @dev Anyone can cancel game if it has been inactive for too long.
   */
  function cancelGame(uint gameId) external {
    (AppStorage storage s, Game storage g) = LibGame.loadGame(gameId);

    LibGame.assertGameNotEndedOrCancelled(g);

    if (g.lastUpdated + 30 days < block.timestamp) {
      g.state = GameState.Cancelled;
      g.lastUpdated = block.timestamp;
    }
  }

  // Getters

  function getGameNonMappingInfo(uint gameId) external view returns (
    GameConfig memory cfg,
    uint id,
    address creator,
    uint numTilesOwned,
    GameState state,
    uint lastUpdated,
    bool transferLocked
  ) {
    (AppStorage storage s, Game storage g) = LibGame.loadGame(gameId);
    cfg = g.cfg;
    id = g.id;
    creator = g.creator;
    numTilesOwned = g.numTilesOwned;
    state = g.state;
    lastUpdated = g.lastUpdated;
    transferLocked = g.transferLocked;
  }

  function getGameTile(uint gameId, uint tileId) external view returns (Tile memory) {
    (AppStorage storage s, Game storage g) = LibGame.loadGame(gameId);
    return g.tiles[tileId];
  }

  function getGamePlayerNonMappingInfo(uint gameId, address player) external view returns (
    uint numTilesOwned,
    address referer,
    uint referralCode
  ) {
    (AppStorage storage s, Game storage g) = LibGame.loadGame(gameId);
    GamePlayer storage gp = g.players[player];
    numTilesOwned = gp.numTilesOwned;
    referer = gp.referer;
    referralCode = gp.referralCode;
  }

  function getGamePlayerTileAtIndex(uint gameId, address player, uint index) external view returns (Tile memory) {
    (AppStorage storage s, Game storage g) = LibGame.loadGame(gameId);
    GamePlayer storage gp = g.players[player];
    return g.tiles[gp.tilesByIndex[index]];
  }
}
