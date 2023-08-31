// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

struct MetaTxContextStorage {
  address trustedForwarder;
}

struct Settings {
  mapping(bytes32 => address) addresses;
  mapping(bytes32 => uint) uints;
}

struct ERC20Token {
  string name;
  string symbol;
  uint8 decimals;
  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowances;
  uint256 totalSupply;
}

enum GameState {
  AwaitingPlayers,
  Started,
  Ended,
  Cancelled
}

struct GameCreationConfig {
  uint numTiles;
  uint tileCost;
  uint maxTilesPerPlayer;
}

struct Tile {
  uint id;
  uint pot;
  address owner;
  bool potClaimed;
}

struct GameNonMappingInfo {
  uint id;
  GameCreationConfig cfg;
  address creator;
  uint numTilesOwned;
  GameState state;
  uint lastUpdated;
  bool transferLocked;
}

struct Game {
  GameNonMappingInfo i;
  mapping(uint => Tile) tiles;
  mapping(address => uint) numTilesOwnedBy;
  mapping(address => mapping(uint => uint)) tileOwnedByIndex;
}

struct Player {
  uint balance;
}

