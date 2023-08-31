// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";


struct AppStorage {
    bool diamondInitialized;
    uint256 reentrancyStatus;
    MetaTxContextStorage metaTxContext;

    ///
    /// Settings
    ///
    Settings settings;

    ///
    /// ERC20
    ///
    mapping(address => ERC20Token) erc20s;

    ///
    /// Games
    ///

    // no. of games
    uint numGames;
    // game id => game
    mapping(uint => Game) games;
    
    ///
    /// Users
    ///
    mapping(address => User) users;

    ///
    /// NFT tokens
    ///
    // collection id => game id
    mapping(uint => uint) tokenGames;
}

library LibAppStorage {
    bytes32 internal constant DIAMOND_APP_STORAGE_POSITION = keccak256("diamond.app.storage");

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = DIAMOND_APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
