pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import {TestBaseContract} from "./utils/TestBaseContract.sol";
import {GameConfig, GameState} from "../src/shared/Structs.sol";
import {LibErrors} from "../src/libs/LibErrors.sol";

contract TestGamePlayFacet is TestBaseContract {
    GameConfig cfg;
    address account3;
    address account4;

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

    // Test game play does update tile for a given player
    function test_GamePlayTileUpdate() external {
        diamond.createGame(cfg);

        uint _playerCount = 4;
        address[] memory players = _get_players(_playerCount);

        // give players equal chance to join.
        _joinPlayersEqualChance(1, players, cfg.numTiles);

        

        // fill tileIds array with id 1-16
        uint16[] memory tileIds = new uint16[](cfg.numTiles);
        for (uint i = 0; i < tileIds.length; i++) {
            tileIds[i] = uint16(i+1);
        }

        address _player1 = players[0];
        address[] memory _newOwners = _get_same_players(3, _player1);

        // tile ids to update for _player1
        uint[] memory _tileIds = new uint[](3);
        _tileIds[0] = 2;
        _tileIds[1] = 3;
        _tileIds[2] = 4;

        bytes32 _hash = compute_hash(1, _tileIds, _newOwners);
        bytes memory _authSig = compute_sig(_hash);

        vm.prank(account0);     // account0 is Authorized Signer.
        diamond.updateTileOwners(1, _tileIds, _newOwners, _authSig);

        // check that tile owners were updated
        assertEq(diamond.getGameTile(1,1).owner, _player1);
        assertEq(diamond.getGameTile(1,2).owner, _player1);
        assertEq(diamond.getGameTile(1,3).owner, _player1);
        assertEq(diamond.getGameTile(1,4).owner, _player1);
    }

    // Test game ends when all tiles are owned by a player
    function test_GamePlayGameEnded() external {
        diamond.createGame(cfg);

        uint _playerCount = 4;
        address[] memory players = _get_players(_playerCount);

        // give players equal chance to join.
        for (uint i = 0; i < 16; i++) {
            uint _playerIdx = i % _playerCount;
            vm.startPrank(players[_playerIdx]);
            vm.deal(players[_playerIdx], 0.01 ether);
            diamond.joinGame{value: 0.01 ether}(1, uint16(i+1), 0);
            vm.stopPrank();
        }

        address _player1 = players[0];
        address[] memory _newOwners = _get_same_players(16, _player1);

        uint[] memory _tileIds = new uint[](16);
        for (uint i = 0; i < 16; i++) {
            _tileIds[i] = i+1;
        }

        bytes32 _hash = compute_hash(1, _tileIds, _newOwners);
        bytes memory _authSig = compute_sig(_hash);

        vm.prank(account0);
        diamond.updateTileOwners(1, _tileIds, _newOwners, _authSig);

        (,uint id, address creator,,,GameState state,,) = diamond.getGameNonMappingInfo(1);
        assertEq(id, 1);
        assertEq(creator, address(this));
        assertEq(uint(state), uint(GameState.Ended));
    }

    // Test signature replay attack from an unauthorized account
    function test_SignatureReplay() external {
        diamond.createGame(cfg);

        uint _playerCount = 4;
        address[] memory players = _get_players(_playerCount);

        // give players equal chance to join.
        _joinPlayersEqualChance(1, players, cfg.numTiles);
        // fill tileIds array with id 1-16
        uint16[] memory tileIds = new uint16[](cfg.numTiles);
        for (uint i = 0; i < tileIds.length; i++) {
            tileIds[i] = uint16(i+1);
        }

        address _player1 = players[0];
        address[] memory _newOwners = _get_same_players(3, _player1);

        // tile ids to update for _player1
        uint[] memory _tileIds = new uint[](3);
        _tileIds[0] = 6;
        _tileIds[1] = 7;
        _tileIds[2] = 8;

        bytes32 _hash = compute_hash(1, _tileIds, _newOwners);
        bytes memory _authSig = compute_sig(_hash);

        vm.startPrank(account0);     // account0 is Authorized Signer.
        diamond.updateTileOwners(1, _tileIds, _newOwners, _authSig);

        // check that tile owners were updated
        assertEq(diamond.getGameTile(1,1).owner, _player1);
        assertEq(diamond.getGameTile(1,6).owner, _player1);
        assertEq(diamond.getGameTile(1,7).owner, _player1);
        assertEq(diamond.getGameTile(1,8).owner, _player1);

        // update tileIds for _player2
        address _player2 = players[1];
        address[] memory _newOwners2 = _get_same_players(3, _player2);

        bytes32 _hash2 = compute_hash(1, _tileIds, _newOwners2);
        bytes memory _authSig2 = compute_sig(_hash2);
        diamond.updateTileOwners(1, _tileIds, _newOwners2, _authSig2);
        // check that tile owners were updated for player2
        assertEq(diamond.getGameTile(1,6).owner, _player2);
        assertEq(diamond.getGameTile(1,7).owner, _player2);
        assertEq(diamond.getGameTile(1,8).owner, _player2);
        vm.stopPrank();

        // signature replay from unauthorized player1 should revert
        vm.prank(_player1);
        vm.expectRevert(LibErrors.AuthFailed.selector);
        diamond.updateTileOwners(1, _tileIds, _newOwners, _authSig);
    }

    function compute_hash(uint gameId_, uint[] memory tileIds_, address[] memory newOwners_) internal pure returns(bytes32 hash) {
        hash = keccak256(abi.encode(gameId_, tileIds_, newOwners_));
    }

    function compute_sig(bytes32 hash_) internal view returns(bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(account0_Key, hash_);
        return abi.encodePacked(r, s, v);
    }

    function _get_same_players(uint len, address elem) internal returns(address[] memory _array) {
        _array = new address[](len);
        for(uint i=0; i<len; ++i) {
            _array[i] = elem;
        }
    }

    function _get_players(uint playerCount) internal returns(address[] memory _players) {
        _players = new address[](playerCount);
        for(uint i=0; i<playerCount; ++i) {
            _players[i] = vm.addr(0xff + i);
        }
    }

    function _joinPlayersEqualChance(uint gameId_, address[] memory players_, uint _tileCount) internal {
            for (uint i = 0; i < _tileCount; i++) {
                uint _playerIdx = i % players_.length;
                vm.startPrank(players_[_playerIdx]);
                vm.deal(players_[_playerIdx], 0.01 ether);
                diamond.joinGame{value: 0.01 ether}(gameId_, uint16(i+1), 0);
                vm.stopPrank();
            }
    }
}