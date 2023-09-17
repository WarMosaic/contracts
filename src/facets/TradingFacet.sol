// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibSignature } from "../libs/LibSignature.sol";
import { LibGame } from "../libs/LibGame.sol";
import { LibErrors } from "../libs/LibErrors.sol";
import { MetaContext } from "../shared/MetaContext.sol";

error InvalidTrade(uint gameId, uint tileId);
error InsufficientFundsToBuy(uint amount);

contract TradingFacet is MetaContext {
  event TileTraded(uint gameId, uint tileId, address buyer, uint amount);

  function settleTileTrade(TradeSigData calldata data, bytes calldata sellerSig, bytes calldata buyerSig, bytes calldata authSig) external {
    (AppStorage storage s, Game storage g, Tile storage t) = LibGame.loadGameTile(data.gameId, data.tileId);
    
    LibGame.assertGameState(g, GameState.Started);

    if (t.owner == data.buyerAddress) {
      revert InvalidTrade(data.gameId, data.tileId);
    }
    if (data.deadline < block.timestamp) {
      revert LibErrors.SigExpired();
    }

    {
      // prevent stack too deep
      bytes32 sigHash = keccak256(abi.encode(data.gameId, data.tileId, t.owner, data.amount, data.deadline));
      LibSignature.assertSignedHash(sigHash);
      LibSignature.assertByAuthorizedSigner(sigHash, authSig);
      LibSignature.assertBySigner(sigHash, sellerSig, t.owner, "seller");
      LibSignature.assertBySigner(sigHash, buyerSig, data.buyerAddress, "buyer");
    }

    User storage buyer = s.users[data.buyerAddress];
    if (buyer.balance < data.amount) {
      revert InsufficientFundsToBuy(data.amount);
    }

    {
      // cache previous owner
      address seller = t.owner;
      // new owner
      LibGame.transferTile(g, t, data.buyerAddress);

      // money transfer
      unchecked {
        buyer.balance -= data.amount;
        (uint finalAmount, ) = LibGame.calculateAndApplyFeesForGame(g, FeeType.Trading, data.amount, g.players[t.owner].referer);
        s.users[seller].balance += finalAmount;
      }

      g.lastUpdated = block.timestamp;
    }

    emit TileTraded(data.gameId, data.tileId, data.buyerAddress, data.amount);
  }
}

