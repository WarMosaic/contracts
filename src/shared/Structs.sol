// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

struct UintList {
  mapping(uint => uint) reverseMap;
  mapping(uint => uint) list;
  uint len;
}

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

enum FeeType {
  Joining,
  Trading
}

enum GameState {
  AwaitingPlayers,
  Started,
  Ended,
  TimedOut
}

struct Tile {
  uint16 id;    // struct packing, since id cannot exceed 1,024.
  address owner;
  bool potClaimed;
  uint pot;
}

struct GameConfig {
  uint numTiles;
  uint tileCost;
  uint maxTilesPerPlayer;
}

struct GamePlayer {
  address referer;
  uint referralCode;
  uint claimableReward;
  uint numTilesOwned;
  UintList tilesOwned;
}

struct GamePlayerNonMappingInfo {
  address referer;
  uint referralCode;
  uint claimableReward;
  uint numTilesOwned;
}

struct Game {
  GameConfig cfg;
  uint id;
  address creator;
  address winner;
  uint numTilesOwned;
  uint numTilesPotsClaimed;
  GameState state;
  uint lastUpdated;
  bool transferLocked;
  mapping(uint => Tile) tiles;
  mapping(address => GamePlayer) players;
  mapping(uint => address) playersByReferralCode;
}

struct GameNonMappingInfo {
  GameConfig cfg;
  uint id;
  address creator;
  address winner;
  uint numTilesOwned;
  uint numTilesPotsClaimed;
  GameState state;
  uint lastUpdated;
  bool transferLocked;
}

struct User {
  uint balance;
}

struct TradeSigData {
  uint gameId;
  uint tileId;
  uint amount;
  uint deadline;
  address buyerAddress;
}