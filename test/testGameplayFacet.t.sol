pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import {TestBaseContract} from "./utils/TestBaseContract.sol";
import {GameConfig, GameState} from "../src/shared/Structs.sol";

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
        for (uint i = 0; i < 16; i++) {
            uint _playerIdx = i % _playerCount;
            vm.startPrank(players[_playerIdx]);
            vm.deal(players[_playerIdx], 0.01 ether);
            diamond.joinGame{value: 0.01 ether}(1, uint16(i+1), 0);
            vm.stopPrank();
        }

        // fill tileIds array with id 1-16
        uint16[] memory tileIds = new uint16[](16);
        for (uint i = 0; i < 16; i++) {
            tileIds[i] = uint16(i+1);
        }

        address _player1 = players[0];
        address[] memory _newOwners = _get_players(3, _player1);

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
        address[] memory _newOwners = _get_players(16, _player1);

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

    function compute_hash(uint gameId_, uint[] memory tileIds_, address[] memory newOwners_) internal pure returns(bytes32 hash) {
        hash = keccak256(abi.encode(gameId_, tileIds_, newOwners_));
    }

    function compute_sig(bytes32 hash_) internal view returns(bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(account0_Key, hash_);
        return abi.encodePacked(r, s, v);
    }

    function _get_players(uint len, address elem) internal returns(address[] memory _array) {
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
}