pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import {TestBaseContract} from "./utils/TestBaseContract.sol";
import {GameConfig, GameState, TradeSigData, Tile} from "../src/shared/Structs.sol";

contract TestSettleFacet is TestBaseContract {
    GameConfig cfg;

    function setUp() public override {
        super.setUp();

        cfg = GameConfig({
            numTiles: 16,
            maxTilesPerPlayer: 4,
            tileCost: 0.02 ether
        });
    }

    function test_TradeTile() external {
        uint tileCost_ = 0.02 ether;
        address[] memory _players = new address[](4);
        _players = _get_players(4);

        diamond.createGame(cfg);

        for (uint i = 0; i < 16; i++) {
            vm.startPrank(_players[i%4]);
            vm.deal(_players[i%4], tileCost_);
            diamond.joinGame{value: tileCost_}(1, uint16(i+1), 0);
            vm.stopPrank();
        }

        (,,,,,GameState state,,) = diamond.getGameNonMappingInfo(1);
        assertEq(uint(state), uint(GameState.Started));

        // seller: player0, buyer: player1
        address _seller = _players[0];
        address _buyer = _players[1];
        TradeSigData memory _tradeData = TradeSigData({
            gameId: 1,
            tileId: 1,
            amount: tileCost_,
            deadline: block.timestamp + 60,
            buyerAddress: _buyer
        });

        uint _sellerKey = 0xff;
        uint _buyerKey = 0xff + 1;

        bytes32 _tradeHashData = computeTradeDataHash(_tradeData, _seller);
        bytes memory _sellerSig = _compute_sig(_tradeHashData, _sellerKey);
        bytes memory _buyerSig = _compute_sig(_tradeHashData, _buyerKey);
        bytes memory _authSig = _compute_sig(_tradeHashData, authAccountKey);

        // deposit before trading
        vm.prank(_buyer);
        vm.deal(_buyer, tileCost_);
        diamond.deposit{value: tileCost_}();

        uint initSellerBal = diamond.getUserNonMappingInfo(_seller).balance;
        diamond.settleTileTrade(_tradeData, _sellerSig, _buyerSig, _authSig);
        uint finalSellerBal = diamond.getUserNonMappingInfo(_seller).balance;

        Tile memory purchasedTile = diamond.getGameTile(1,1);
        assertNotEq(purchasedTile.owner, _seller);
        assertEq(purchasedTile.owner, _buyer);
        assertGt(finalSellerBal, initSellerBal);
    }


    function computeTradeDataHash(TradeSigData memory data_, address tileOwner_) internal returns(bytes32 hash_) {
        hash_ = keccak256(abi.encode(
            data_.gameId,
            data_.tileId,
            tileOwner_,
            data_.amount,
            data_.deadline
        ));
    }
}