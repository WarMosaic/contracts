// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibSignature } from "../libs/LibSignature.sol";
import { LibGame } from "../libs/LibGame.sol";
import { MetaContext } from "../shared/MetaContext.sol";

error InsufficientFundsToBuy(uint amount);

contract GameplayFacet is MetaContext {
  event TileTraded(uint gameId, uint tileId, address buyer, uint amount);
  event TileOwnershipsUpdated(uint gameId);

  function settleTileTrade(uint gameId, uint tileId, address buyerAddress, uint amount, bytes calldata sellerSig, bytes calldata buyerSig, bytes calldata authSig) external {
    (AppStorage storage s, Game storage g, Tile storage t) = LibGame.loadGameTile(gameId, tileId);
    
    LibGame.assertGameState(g, GameState.Started);

    bytes32 sigHash = keccak256(abi.encode(gameId, tileId, buyerAddress, amount));
    LibSignature.assertByAuthorizedSigner(sigHash, authSig);
    LibSignature.assertBySigner(sigHash, sellerSig, t.owner, "seller");
    LibSignature.assertBySigner(sigHash, buyerSig, buyerAddress, "buyer");

    Player storage buyer = s.players[buyerAddress];
    if (buyer.balance < amount) {
      revert InsufficientFundsToBuy(amount);
    }

    buyer.balance -= amount;
    s.players[t.owner].balance += amount;
    t.owner = buyerAddress;

    LibGame.updateQuadStatus(s, g, t);

    g.i.lastUpdated = block.timestamp;

    emit TileTraded(gameId, tileId, buyerAddress, amount);
  }


  function updateTileOwners(uint gameId, uint[] calldata tileIds, address[] calldata newOwners, bytes calldata authSig) external {
    (AppStorage storage s, Game storage g) = LibGame.loadGame(gameId);

    LibGame.assertGameState(g, GameState.Started);

    bytes32 sigHash = keccak256(abi.encode(gameId, tileIds, newOwners));
    LibSignature.assertByAuthorizedSigner(sigHash, authSig);

    for (uint i = 0; i < tileIds.length; i++) {
      uint tileId = tileIds[i];
      address owner = newOwners[i];

      LibGame.assertGameTileId(g, tileId);

      g.tiles[tileId].owner = owner;

      LibGame.updateQuadStatus(s, g, g.tiles[tileId]);
    }

    g.i.lastUpdated = block.timestamp;

    emit TileOwnershipsUpdated(gameId);
  }
}

