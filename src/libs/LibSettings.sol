// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "../shared/Structs.sol";
import { LibConstants } from "./LibConstants.sol";
import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";

library LibSettings {
  function getGameCreatorFeeBips(FeeType feeType) internal view returns (uint) {
    if (feeType == FeeType.Joining) {
      return LibAppStorage.diamondStorage().settings.i[LibConstants.JOINING_GAME_CREATOR_FEE_BIPS];
    } else {
      return LibAppStorage.diamondStorage().settings.i[LibConstants.TRADING_GAME_CREATOR_FEE_BIPS];
    }
  }

  function getRefererFeeBips(FeeType feeType) internal view returns (uint) {
    if (feeType == FeeType.Joining) {
      return LibAppStorage.diamondStorage().settings.i[LibConstants.JOINING_REFERER_FEE_BIPS];
    } else {
      return LibAppStorage.diamondStorage().settings.i[LibConstants.TRADING_REFERER_FEE_BIPS];
    }
  }

  function getProjectFeeBips(FeeType feeType) internal view returns (uint) {
    if (feeType == FeeType.Joining) {
      return LibAppStorage.diamondStorage().settings.i[LibConstants.JOINING_PROJECT_FEE_BIPS];
    } else {
      return LibAppStorage.diamondStorage().settings.i[LibConstants.TRADING_PROJECT_FEE_BIPS];
    }
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
