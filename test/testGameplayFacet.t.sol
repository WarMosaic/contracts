pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import { TestBaseContract } from "./utils/TestBaseContract.sol";
import { GameConfig, GameState, GameNonMappingInfo } from "../src/shared/Structs.sol";
import { LibErrors } from "../src/libs/LibErrors.sol";

contract TestGamePlayFacet is TestBaseContract {
  GameConfig internal cfg;

  function setUp() public override {
    super.setUp();

    cfg = GameConfig({ numTiles: 16, maxTilesPerPlayer: 4, tileCost: 0.01 ether });
  }

  function testGamePlayTileUpdate() external {
    (uint _gameId, address[] memory _players) = setupBasicGame(cfg);

    address _player1 = _players[0];
    address[] memory _newOwners = buildArrayOfDuplicateAddresses(3, _player1);

    // tile ids to update for _player1
    uint[] memory _tileIds = new uint[](3);
    _tileIds[0] = 2;
    _tileIds[1] = 3;
    _tileIds[2] = 4;

    uint _deadline = block.timestamp;
    bytes32 _hash = computeTileUpdateHash(_gameId, _tileIds, _newOwners, _deadline);
    bytes memory _authSig = computeAuthSig(_hash);

    vm.prank(account0); // account0 is Authorized Signer.
    diamond.updateTileOwners(_gameId, _tileIds, _newOwners, _deadline, _authSig);

    // check that tile owners were updated
    assertEq(diamond.getGameTile(_gameId, 1).owner, _player1);
    assertEq(diamond.getGameTile(_gameId, 2).owner, _player1);
    assertEq(diamond.getGameTile(_gameId, 3).owner, _player1);
    assertEq(diamond.getGameTile(_gameId, 4).owner, _player1);
  }

  function testGamePlayTileUpdateDeadlineExpired() external {
    (uint _gameId, address[] memory _players) = setupBasicGame(cfg);

    address _player1 = _players[0];
    address[] memory _newOwners = buildArrayOfDuplicateAddresses(3, _player1);

    // tile ids to update for _player1
    uint[] memory _tileIds = new uint[](3);
    _tileIds[0] = 2;
    _tileIds[1] = 3;
    _tileIds[2] = 4;

    uint _deadline = block.timestamp - 1;
    bytes32 _hash = computeTileUpdateHash(_gameId, _tileIds, _newOwners, _deadline);
    bytes memory _authSig = computeAuthSig(_hash);

    vm.prank(account0); // account0 is Authorized Signer.
    vm.expectRevert(LibErrors.SigExpired.selector);
    diamond.updateTileOwners(_gameId, _tileIds, _newOwners, _deadline, _authSig);
  }

  function testGamePlayTileUpdateSigReplayDetection() external {
    (uint _gameId, address[] memory _players) = setupBasicGame(cfg);

    address _player1 = _players[0];
    address[] memory _newOwners = buildArrayOfDuplicateAddresses(3, _player1);

    // tile ids to update for _player1
    uint[] memory _tileIds = new uint[](3);
    _tileIds[0] = 2;
    _tileIds[1] = 3;
    _tileIds[2] = 4;

    uint _deadline = block.timestamp;
    bytes32 _hash = computeTileUpdateHash(_gameId, _tileIds, _newOwners, _deadline);
    bytes memory _authSig = computeAuthSig(_hash);

    vm.prank(account0); // account0 is Authorized Signer.
    diamond.updateTileOwners(_gameId, _tileIds, _newOwners, _deadline, _authSig);

    // second call should fail
    vm.prank(_player1);
    vm.expectRevert(LibErrors.InvalidatedSigHash.selector);
    diamond.updateTileOwners(_gameId, _tileIds, _newOwners, _deadline, _authSig);
  }

  // Test game ends when all tiles are owned by a player
  function testGamePlayTileUpdateGameEnded() external {
    (uint _gameId, address[] memory _players) = setupBasicGame(cfg);

    address _player1 = _players[0];
    address[] memory _newOwners = buildArrayOfDuplicateAddresses(16, _player1);
    uint[] memory _tileIds = getTileIds(16);

    uint _deadline = block.timestamp;
    bytes32 _hash = computeTileUpdateHash(_gameId, _tileIds, _newOwners, _deadline);
    bytes memory _authSig = computeAuthSig(_hash);

    vm.prank(account0);
    diamond.updateTileOwners(_gameId, _tileIds, _newOwners, _deadline, _authSig);

    GameNonMappingInfo memory info = diamond.getGameNonMappingInfo(_gameId);
    assertEq(info.winner, _player1);
    assertEq(uint(info.state), uint(GameState.Ended));
  }

  // Helper functions

  function computeTileUpdateHash(
    uint gameId_,
    uint[] memory tileIds_,
    address[] memory newOwners_,
    uint deadline_
  ) internal pure returns (bytes32 hash) {
    hash = keccak256(abi.encode(gameId_, tileIds_, newOwners_, deadline_));
  }

  function buildArrayOfDuplicateAddresses(
    uint len,
    address elem
  ) internal pure returns (address[] memory array_) {
    array_ = new address[](len);
    for (uint i = 0; i < len; ++i) {
      array_[i] = elem;
    }
  }
}
