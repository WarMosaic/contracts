pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import { TestBaseContract } from "./utils/TestBaseContract.sol";
import { GameConfig, GameState, TradeSigData, Tile } from "../src/shared/Structs.sol";

contract TestSettleFacet is TestBaseContract {
  GameConfig internal cfg;

  function setUp() public override {
    super.setUp();

    cfg = GameConfig({ numTiles: 16, maxTilesPerPlayer: 4, tileCost: 0.02 ether });
  }

  function testTradeTile() external {
    (uint _gameId, address[] memory _players) = setupBasicGame(cfg);

    uint tileCost_ = 0.05 ether;

    // seller: player0, buyer: player1
    address _seller = _players[0];
    address _buyer = _players[1];
    TradeSigData memory _tradeData = TradeSigData({
      gameId: _gameId,
      tileId: 1,
      amount: tileCost_,
      deadline: block.timestamp + 60,
      buyerAddress: _buyer
    });

    bytes32 _tradeHashData = computeTradeDataHash(_tradeData, _seller);
    bytes memory _sellerSig = computeSig(_tradeHashData, 0xff);
    bytes memory _buyerSig = computeSig(_tradeHashData, 0xff + 1);
    bytes memory _authSig = computeAuthSig(_tradeHashData);

    // deposit before trading
    vm.prank(_buyer);
    vm.deal(_buyer, tileCost_);
    diamond.deposit{ value: tileCost_ }();

    // avoid stack too deep
    {
        uint initSellerBal = diamond.getUserNonMappingInfo(_seller).balance;
        diamond.settleTileTrade(_tradeData, _sellerSig, _buyerSig, _authSig);
        uint finalSellerBal = diamond.getUserNonMappingInfo(_seller).balance;

        Tile memory purchasedTile = diamond.getGameTile(_gameId, 1);
        assertEq(purchasedTile.owner, _buyer);
        assertGt(finalSellerBal, initSellerBal);
    }
  }

  function computeTradeDataHash(
    TradeSigData memory data_,
    address tileOwner_
  ) internal returns (bytes32 hash_) {
    hash_ = keccak256(
      abi.encode(data_.gameId, data_.tileId, tileOwner_, data_.amount, data_.deadline)
    );
  }
}
