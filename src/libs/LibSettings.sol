// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { LibConstants } from "./LibConstants.sol";
import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";

library LibSettings {
  function getUint(bytes32 id) internal view returns (uint) {
    return LibAppStorage.diamondStorage().settings.uints[id];
  }

  function setUint(bytes32 id, uint val) internal {
    LibAppStorage.diamondStorage().settings.uints[id] = val;
  }

  function getAddress(bytes32 id) internal view returns (address) {
    return LibAppStorage.diamondStorage().settings.addresses[id];
  }

  function setAddress(bytes32 id, address val) internal {
    LibAppStorage.diamondStorage().settings.addresses[id] = val;
  }

  function getAuthorizedSigner() internal view returns (address) {
    return LibAppStorage.diamondStorage().settings.addresses[LibConstants.AUTHORIZED_SIGNER];
  }
}
