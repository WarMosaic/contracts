pragma solidity ^0.8.21;

import {TestBaseContract} from "./utils/TestBaseContract.sol";
import "forge-std/Test.sol";
import {GameConfig} from "../src/shared/Structs.sol";
import "../src/facets/GameFacet.sol";

contract TestGameFacet is TestBaseContract {
    GameConfig cfg;
    address account3;
    address account4;
    mapping(uint => bool) validTileCount;

    function setUp() public override {
        super.setUp();
        account3 = vm.addr(3);
        account4 = vm.addr(4);

        cfg = GameConfig({
            numTiles: 16,
            maxTilesPerPlayer: 4,
            tileCost: 0.01 ether
        });
    }

    function test_CreateGame() external {
        vm.prank(account0);
        diamond.createGame(cfg);

        (,uint id, address creator,,,GameState state,,) = diamond.getGameNonMappingInfo(1);
        assertEq(id, 1);
        assertEq(uint(state), uint(GameState.AwaitingPlayers));
        assertEq(creator, account0);
    }

    function testFuzz_CreateGame(uint numTiles_, uint96 tileCost_) external {
        _fillValidTileCount();
        numTiles_ = bound(numTiles_, 16, 1024);
        vm.assume(validTileCount[numTiles_]);
        vm.assume(tileCost_ >= 0.01 ether);

        cfg.numTiles = numTiles_;
        cfg.tileCost = tileCost_;

        emit log_uint(numTiles_);
        emit log_uint(tileCost_);
        diamond.createGame(cfg);
        assertEq(diamond.getGameCount(), 1);
    }

    function test_CreateWithWrongTileCount() external {
        uint256 _numTiles = 15;
        vm.expectRevert(abi.encodeWithSelector(GameInvalidNumTiles.selector, _numTiles));
        cfg.numTiles = _numTiles;
        diamond.createGame(cfg);

        _numTiles = 24;
        vm.expectRevert(abi.encodeWithSelector(GameInvalidNumTiles.selector, _numTiles));
        cfg.numTiles = _numTiles;
        diamond.createGame(cfg);
    }

    function test_JoinGame() external {
        vm.startPrank(account0);
        address[] memory players = new address[](4);
        players[0] = account0;
        players[1] = account1;
        players[2] = account2;
        players[3] = account3;

        diamond.createGame(cfg);

        // give players equal chance to join.
        for (uint i = 0; i < 16; i++) {
            vm.startPrank(players[i%4]);
            vm.deal(players[i%4], 0.01 ether);
            diamond.joinGame{value: 0.01 ether}(1, uint16(i+1), 0);
            vm.stopPrank();
        }

        (,uint id, address creator,,,GameState state,,) = diamond.getGameNonMappingInfo(1);
        assertEq(id, 1);
        assertEq(creator, account0);
        assertEq(uint(state), uint(GameState.Started));
    }

    function _fillValidTileCount() internal {
        validTileCount[16] = true;
        validTileCount[64] = true;
        validTileCount[256] = true;
        validTileCount[400] = true;
        validTileCount[576] = true;
        validTileCount[784] = true;
        validTileCount[1024] = true;
    }
}