// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "../libs/LibAppStorage.sol";
import { MetaContext } from "../shared/MetaContext.sol";

contract PlayerFacet is MetaContext {
  function deposit() external payable {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.players[_msgSender()].balance += msg.value;
  }

  function withdraw(uint amount) external {
    AppStorage storage s = LibAppStorage.diamondStorage();
    address player = _msgSender();
    if (s.players[player].balance < amount) {
      amount = s.players[player].balance;
    }
    s.players[player].balance = 0;
    payable(player).transfer(amount);
  }

  function getPlayerNonMappingInfo(address player) external view returns (Player memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    return s.players[player];
  }
}

