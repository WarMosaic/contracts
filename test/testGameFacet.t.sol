pragma solidity ^0.8.21;

import { TestBaseContract } from "./utils/TestBaseContract.sol";
import "forge-std/Test.sol";
import { GameConfig, GameNonMappingInfo, GameState } from "../src/shared/Structs.sol";
import { GameInvalidNumTiles } from "../src/facets/GameFacet.sol";

contract TestGameFacet is TestBaseContract {
  GameConfig internal cfg;
  address internal account3;
  address internal account4;
  mapping(uint => bool) internal validTileCountForGameCreation;

  function setUp() public override {
    super.setUp();
    account3 = vm.addr(3);
    account4 = vm.addr(4);

    cfg = GameConfig({ numTiles: 16, maxTilesPerPlayer: 4, tileCost: 0.01 ether });
  }

  function testCreateGame() external {
    vm.prank(account0);
    createGame(cfg);

    uint numGames = diamond.getGameCount();
    assertEq(numGames, 1);

    GameNonMappingInfo memory gameInfo = diamond.getGameNonMappingInfo(1);
    assertEq(gameInfo.id, 1);
    assertEq(gameInfo.cfg.numTiles, cfg.numTiles);
    assertEq(gameInfo.cfg.maxTilesPerPlayer, cfg.maxTilesPerPlayer);
    assertEq(gameInfo.cfg.tileCost, cfg.tileCost);
    assertEq(gameInfo.creator, account0);
    assertEq(gameInfo.winner, address(0));
    assertEq(gameInfo.numTilesOwned, 0);
    assertEq(gameInfo.numTilesPotsClaimed, 0);
    assertEq(uint(gameInfo.state), uint(GameState.AwaitingPlayers));
  }

  function testCreateGameFuzzy(uint numTiles_, uint96 tileCost_) external {
    setupValidTileCountsForGameCreation();
    numTiles_ = bound(numTiles_, 16, 1024);
    vm.assume(validTileCountForGameCreation[numTiles_]);
    vm.assume(tileCost_ >= 0.01 ether);

    cfg.numTiles = numTiles_;
    cfg.tileCost = tileCost_;

    uint gameId = createGame(cfg);
    assertEq(diamond.getGameCount(), 1);
    assertEq(gameId, 1);
  }

  function testCreateGameWithWrongTileCount() external {
    uint256 _numTiles = 15;
    vm.expectRevert(abi.encodeWithSelector(GameInvalidNumTiles.selector, _numTiles));
    cfg.numTiles = _numTiles;
    createGame(cfg);

    _numTiles = 24;
    vm.expectRevert(abi.encodeWithSelector(GameInvalidNumTiles.selector, _numTiles));
    cfg.numTiles = _numTiles;
    createGame(cfg);
  }

  function testJoinGameNotYetStarted() external {
    vm.startPrank(account0);
    uint gameId = createGame(cfg);

    address[] memory players = getPlayers(4);

    // all but 1 tile taken
    joinGameWithPlayersEqualChance(gameId, players, 15);

    GameNonMappingInfo memory info = diamond.getGameNonMappingInfo(gameId);
    assertEq(uint(info.state), uint(GameState.AwaitingPlayers));
    assertEq(info.numTilesOwned, 15);
  }

  function testJoinGameAndThenStarted() external {
    vm.startPrank(account0);
    uint gameId = createGame(cfg);

    address[] memory players = getPlayers(4);

    // all tiles taken
    joinGameWithPlayersEqualChance(gameId, players, 16);

    GameNonMappingInfo memory info = diamond.getGameNonMappingInfo(gameId);
    assertEq(uint(info.state), uint(GameState.Started));
    assertEq(info.numTilesOwned, 16);
  }

  // Internal methods

  function setupValidTileCountsForGameCreation() internal {
    validTileCountForGameCreation[16] = true;
    validTileCountForGameCreation[64] = true;
    validTileCountForGameCreation[256] = true;
    validTileCountForGameCreation[400] = true;
    validTileCountForGameCreation[576] = true;
    validTileCountForGameCreation[784] = true;
    validTileCountForGameCreation[1024] = true;
  }
}
