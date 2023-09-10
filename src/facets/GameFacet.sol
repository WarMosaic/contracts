// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibUintList } from "../libs/LibUintList.sol";
import { LibGame } from "../libs/LibGame.sol";
import { MetaContext } from "../shared/MetaContext.sol";

error GameInvalidNumTiles(uint numTiles);
error GameInvalidMaxTilesPerPlayer(uint maxTilesPerPlayer);
error GameInvalidTileCost(uint tileCost);
error GameTileAlreadyOwned(uint gameId, uint tileId);
error GameMaxTilesPerPlayerReached(uint gameId, address player);
error InsufficientFundsToJoinGame(uint amount);

contract GameFacet is MetaContext {  
  using LibUintList for UintList;

  event GameCreated(address creator, uint gameId);
  event GameJoined(uint gameId, uint tileId, address player);

  function createGame(GameConfig memory cfg) external {
    /*
      Only square numbers divisible by 4 are allowed, with a min of 16 tiles and a max of 1024:

      16, 64, 144, 256, 400, 576, 784, 1024
    */
    // first let's check the number is divisible by 4
    if (cfg.numTiles % 4 != 0) {
      revert GameInvalidNumTiles(cfg.numTiles);
    }
    // now let's check against a list
    bool valid = false;
    uint[8] memory validNumTiles = [uint(16), 64, 144, 256, 400, 576, 784, 1024];
    for (uint i = 0; i < validNumTiles.length; i++) {
      if (cfg.numTiles == validNumTiles[i]) {
        valid = true;
        break;
      }
    }
    if (!valid) {
      revert GameInvalidNumTiles(cfg.numTiles);
    }

    // tile cost must be at least 0.01 ether
    if (cfg.tileCost < 0.01 ether) {
      revert GameInvalidTileCost(cfg.tileCost);
    }

    // max tiles per player must be at least 1 and no more than the total number of tiles
    if (cfg.maxTilesPerPlayer < 1 || cfg.maxTilesPerPlayer > cfg.numTiles) {
      revert GameInvalidMaxTilesPerPlayer(cfg.maxTilesPerPlayer);
    }

    AppStorage storage s = LibAppStorage.diamondStorage();

    // create game
    s.numGames++;
    Game storage g = s.games[s.numGames];

    // initialize game
    g.id = s.numGames;
    g.creator = _msgSender();
    g.cfg = cfg;
    g.state = GameState.AwaitingPlayers;
    g.lastUpdated = block.timestamp;

    emit GameCreated(g.creator, s.numGames);
  }

  function joinGame(uint gameId, uint16 tileId, uint referralCode) external payable {
    (AppStorage storage s, Game storage g, Tile storage t) = LibGame.loadGameTile(gameId, tileId);

    address player = _msgSender();

    LibGame.assertGameState(g, GameState.AwaitingPlayers);

    // tile must not already be owned
    if (t.owner != address(0)) {
      revert GameTileAlreadyOwned(gameId, tileId);
    }

    // player must not already own the max number of tiles
    if (g.players[player].numTilesOwned == g.cfg.maxTilesPerPlayer) {
      revert GameMaxTilesPerPlayerReached(gameId, player);
    }

    // player must send enough funds to cover the tile cost
    if (msg.value < g.cfg.tileCost) {
      revert InsufficientFundsToJoinGame(msg.value);
    }

    // assign tile to player
    LibGame.transferTile(g, t, player);

    // if this is the first tile then set the referer and referral code
    // for subsequent tiles, it will use the already saved referer, thus preventing a player from using their own referral code
    GamePlayer storage gp = g.players[player];
    if (gp.numTilesOwned == 1) {
      gp.referer = g.playersByReferralCode[referralCode];
      gp.referralCode = uint(keccak256(abi.encodePacked(player, _msgData(), g.lastUpdated))) % 10000;
      g.playersByReferralCode[referralCode] = player;
    }

    // apply fees
    (uint finalAmount, ) = LibGame.calculateAndApplyFeesForGame(g, FeeType.Joining, msg.value, gp.referer);

    // add tile to game
    g.numTilesOwned++;
    t.id = tileId;
    t.pot = finalAmount;
    t.potClaimed = false;

    // ready to start game once all tiles are owned
    if (g.numTilesOwned == g.cfg.numTiles) {
      g.state = GameState.Started;
    }

    // update timestamp flag
    g.lastUpdated = block.timestamp;

    emit GameJoined(gameId, tileId, player);
  }

  function claimRewards(uint gameId) external {
    (AppStorage storage s, Game storage g) = LibGame.loadGame(gameId);
    address player = _msgSender();

    LibGame.assertGameIsOver(g);

    GamePlayer storage gp = g.players[_msgSender()];

    if (gp.claimableReward > 0) {
      uint amount = gp.claimableReward;
      gp.claimableReward = 0;
      payable(player).transfer(amount);
    }
  }

  /**
   * @dev Anyone can timeout a game if it has been inactive for too long.
   */
  function timeoutGame(uint gameId) external {
    (AppStorage storage s, Game storage g) = LibGame.loadGame(gameId);

    LibGame.assertGameIsActive(g);

    if (g.lastUpdated + 7 days < block.timestamp) {
      g.state = GameState.TimedOut;
      g.lastUpdated = block.timestamp;
    }
  }

  // Getters

  function getGameNonMappingInfo(uint gameId) external view returns (
    GameConfig memory cfg,
    uint id,
    address creator,
    address winner,
    uint numTilesOwned,
    GameState state,
    uint lastUpdated,
    bool transferLocked
  ) {
    (AppStorage storage s, Game storage g) = LibGame.loadGame(gameId);
    cfg = g.cfg;
    id = g.id;
    creator = g.creator;
    winner = g.winner;
    numTilesOwned = g.numTilesOwned;
    state = g.state;
    lastUpdated = g.lastUpdated;
    transferLocked = g.transferLocked;
  }

  function getGameTile(uint gameId, uint16 tileId) external view returns (Tile memory) {
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
    return g.tiles[gp.tilesOwned.get(index)];
  }
}
