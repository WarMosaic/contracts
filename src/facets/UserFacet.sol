// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "../libs/LibAppStorage.sol";
import { MetaContext } from "../shared/MetaContext.sol";

contract UserFacet is MetaContext {
  function deposit() external payable {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.users[_msgSender()].balance += msg.value;
  }

  function withdraw(uint amount) external {
    AppStorage storage s = LibAppStorage.diamondStorage();
    address user = _msgSender();
    if (s.users[user].balance < amount) {
      amount = s.users[user].balance;
    }
    s.users[user].balance = 0;
    payable(user).transfer(amount);
  }

  function getUserNonMappingInfo(address user) external view returns (User memory) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    return s.users[user];
  }
}

