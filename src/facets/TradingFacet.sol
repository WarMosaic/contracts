// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibSignature } from "../libs/LibSignature.sol";
import { LibGame } from "../libs/LibGame.sol";
import { MetaContext } from "../shared/MetaContext.sol";

error InsufficientFundsToBuy(uint amount);

contract TradingFacet is MetaContext {
  event TileTraded(uint gameId, uint tileId, address buyer, uint amount);

  function settleTileTrade(uint gameId, uint tileId, address buyerAddress, uint amount, bytes calldata sellerSig, bytes calldata buyerSig, bytes calldata authSig) external {
    (AppStorage storage s, Game storage g, Tile storage t) = LibGame.loadGameTile(gameId, tileId);
    
    LibGame.assertGameState(g, GameState.Started);

    bytes32 sigHash = keccak256(abi.encode(gameId, tileId, buyerAddress, amount));
    LibSignature.assertByAuthorizedSigner(sigHash, authSig);
    LibSignature.assertBySigner(sigHash, sellerSig, t.owner, "seller");
    LibSignature.assertBySigner(sigHash, buyerSig, buyerAddress, "buyer");

    User storage buyer = s.users[buyerAddress];
    if (buyer.balance < amount) {
      revert InsufficientFundsToBuy(amount);
    }

    {
      // new owner
      t.owner = buyerAddress;
      
      // money transfer
      buyer.balance -= amount;
      (uint finalAmount, ) = LibGame.calculateAndApplyFees(amount, g.creator, g.players[t.owner].referer);
      s.users[t.owner].balance += finalAmount;

      LibGame.tryAndClaimQuad(s, g, t);

      g.lastUpdated = block.timestamp;
    }

    emit TileTraded(gameId, tileId, buyerAddress, amount);
  }
}

