// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibSignature } from "../libs/LibSignature.sol";
import { LibGame } from "../libs/LibGame.sol";
import { LibSettings } from "../libs/LibSettings.sol";
import { LibErrors } from "../libs/LibErrors.sol";
import { MetaContext } from "../shared/MetaContext.sol";


contract GameplayFacet is MetaContext {
  event TileOwnershipsUpdated(uint gameId);

  function updateTileOwners(uint gameId, uint[] calldata tileIds, address[] calldata newOwners, uint deadline, bytes calldata authSig) external {
    if(tileIds.length != newOwners.length) revert LibErrors.LengthMismatch();
    if(deadline < block.timestamp) revert LibErrors.SigExpired();
    (AppStorage storage s, Game storage g) = LibGame.loadGame(gameId);

    LibGame.assertGameState(g, GameState.Started);

    bytes32 sigHash = keccak256(abi.encode(gameId, tileIds, newOwners, deadline));
    LibSignature.assertSignedHash(sigHash);
    LibSignature.setSignedHash(sigHash);
    LibSignature.assertByAuthorizedSigner(sigHash, authSig);

    for (uint i = 0; i < tileIds.length; i++) {
      uint tileId = tileIds[i];
      address owner = newOwners[i];

      LibGame.assertGameTileId(g, tileId);

      Tile storage t = g.tiles[tileId];

      if (t.owner != owner) {
        LibGame.transferTile(g, t, owner);
      }
    }

    g.lastUpdated = block.timestamp;

    emit TileOwnershipsUpdated(gameId);
  }
}

