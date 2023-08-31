// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

struct MetaTxContextStorage {
  address trustedForwarder;
}

struct Settings {
  mapping(bytes32 => address) a;
  mapping(bytes32 => uint) i;
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

struct Tile {
  uint id;
  uint pot;
  address owner;
  bool potClaimed;
}

struct GameConfig {
  uint numTiles;
  uint tileCost;
  uint maxTilesPerPlayer;
}

struct GamePlayer {
  uint numTilesOwned;
  address referer;
  uint referralCode;
  mapping(uint => uint) tilesByIndex;
}

struct Game {
  GameConfig cfg;
  uint id;
  address creator;
  uint numTilesOwned;
  GameState state;
  uint lastUpdated;
  bool transferLocked;
  mapping(uint => Tile) tiles;
  mapping(address => GamePlayer) players;
  mapping(uint => address) playersByReferralCode;
}

struct User {
  uint balance;
}

