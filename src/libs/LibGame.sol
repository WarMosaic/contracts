// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { LibSettings } from "./LibSettings.sol";
import { LibUintList } from "./LibUintList.sol";

error InvalidGame(uint gameId);
error InvalidGameTile(uint gameId, uint tileId);
error GameInWrongState(uint gameId);

library LibGame {
  using LibUintList for UintList;

  event QuadClaimed(uint gameId, uint tileId, address player);
  event GameOver(uint gameId, address winner);

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

  function assertGameIsOver(Game storage g) internal view {
    if (g.state != GameState.Ended && g.state != GameState.TimedOut) {
      revert GameInWrongState(g.id);
    }
  }

  function assertGameIsActive(Game storage g) internal view {
    if (g.state == GameState.Ended || g.state == GameState.TimedOut) {
      revert GameInWrongState(g.id);
    }
  }

  function assertGameTileId(Game storage g, uint tileId) internal view {
    if (tileId < 1 || tileId > g.cfg.numTiles) {
      revert InvalidGameTile(g.id, tileId);
    }
  }

  function setupPlayerReferralCode(Game storage g, address player) internal returns (uint) {
    GamePlayer storage gp = g.players[player];
    gp.referralCode = uint(keccak256(abi.encodePacked(player, msg.data, g.lastUpdated))) % 100000000;
    g.playersByReferralCode[gp.referralCode] = player;
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

  function transferTile(Game storage g, Tile storage t, address newOwner) internal {
    // remove from current owner
    // prevent Arithmetic underflow for first time owner
    if(t.owner != address(0)) {
      g.players[t.owner].numTilesOwned--;
      g.players[t.owner].tilesOwned.remove(t.id);
    }

    // add to new owner
    g.players[newOwner].numTilesOwned++;
    g.players[newOwner].tilesOwned.add(t.id);

    // update tile prop
    t.owner = newOwner;

    // post-processing
    if (g.state == GameState.Started) {
      tryAndClaimQuad(g, t);
      tryAndEndGame(g, newOwner);
    }
  }

  function calculateAndApplyFeesForGame(Game storage g, FeeType feeType, uint amount, address referer) internal returns (uint amountMinusFees, uint totalFees) {
    AppStorage storage s = LibAppStorage.diamondStorage();

    uint creatorFeeAmount = (amount * LibSettings.getGameCreatorFeeBips(feeType)) / 10000;
    uint refererFeeAmount = (amount * LibSettings.getRefererFeeBips(feeType)) / 10000;
    uint projectFeeAmount = (amount * LibSettings.getProjectFeeBips(feeType)) / 10000;
    totalFees = creatorFeeAmount + refererFeeAmount + projectFeeAmount;
    amountMinusFees = amount - totalFees;

    address projectWallet = LibSettings.getProjectWallet();

    g.players[g.creator].claimableReward += creatorFeeAmount;

    if (referer != address(0)) {
      g.players[referer].claimableReward += refererFeeAmount;
    } else {
      s.users[projectWallet].balance += refererFeeAmount;
    }

    s.users[projectWallet].balance += projectFeeAmount;
  }

  function tryAndClaimQuad(Game storage g, Tile storage t) private {
    // if quad is not already claimed then try and claim it
    if (t.pot.remaining > 0) {
      // work out quad this tile belongs to
      uint quadStartId = ((t.id - 1) / 4) * 4 + 1;
      uint quadEndId = quadStartId + 3;

      for (uint i = quadStartId; i <= quadEndId; i++) {
        Tile storage quadTile = g.tiles[i];
        
        if (quadTile.owner != t.owner) {
          return;
        }
      }

      // if we get here then all tiles in the quad are owned by the same player
      g.numTilesPotsClaimed += 4;

      for (uint i = quadStartId; i <= quadEndId; i++) {
        Tile storage quadTile = g.tiles[i];
        // transfer pot to owner
        g.players[quadTile.owner].claimableReward += quadTile.pot.remaining;
        g.pot.remaining -= quadTile.pot.remaining;
        quadTile.pot.remaining = 0;
      }

      emit QuadClaimed(g.id, quadStartId, t.owner);
    }
  }

  function tryAndEndGame(Game storage g, address possibleWinner) private {
    if (g.players[possibleWinner].numTilesOwned == g.cfg.numTiles) {
      g.state = GameState.Ended;
      g.winner = possibleWinner;
      g.lastUpdated = block.timestamp;
      emit GameOver(g.id, possibleWinner);
    }
  }
}
