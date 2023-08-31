// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { LibConstants } from "./LibConstants.sol";
import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";

library LibSettings {
  function getGameCreatorFeeBips() internal view returns (uint) {
    return LibAppStorage.diamondStorage().settings.i[LibConstants.GAME_CREATOR_FEE_BIPS];
  }

  function getRefererFeeBips() internal view returns (uint) {
    return LibAppStorage.diamondStorage().settings.i[LibConstants.REFERER_FEE_BIPS];
  }

  function getProjectFeeBips() internal view returns (uint) {
    return LibAppStorage.diamondStorage().settings.i[LibConstants.PROJECT_FEE_BIPS];
  }

  function getStakingFeeBips() internal view returns (uint) {
    return LibAppStorage.diamondStorage().settings.i[LibConstants.STAKING_FEE_BIPS];
  }

  function getMosaicToken() internal view returns (address) {
    return LibAppStorage.diamondStorage().settings.a[LibConstants.MOSAIC_TOKEN];
  }

  function getProjectWallet() internal view returns (address) {
    return LibAppStorage.diamondStorage().settings.a[LibConstants.PROJECT_WALLET];
  }

  function getAuthorizedSignerWallet() internal view returns (address) {
    return LibAppStorage.diamondStorage().settings.a[LibConstants.AUTHORIZED_SIGNER_WALLET];
  }
}
