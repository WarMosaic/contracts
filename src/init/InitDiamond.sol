// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { AppStorage, LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibSettings } from "../libs/LibSettings.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibERC20 } from "../libs/LibERC20.sol";

error DiamondAlreadyInitialized();

contract InitDiamond {
  event InitializeDiamond(address sender);

  function init() external {
    AppStorage storage s = LibAppStorage.diamondStorage();
    if (s.diamondInitialized) {
      revert DiamondAlreadyInitialized();
    }
    s.diamondInitialized = true;

    // initial settings
    s.settings.i[LibConstants.GAME_CREATOR_FEE_BIPS] = 300; // 2%
    s.settings.i[LibConstants.REFERER_FEE_BIPS] = 100; // 2%
    s.settings.i[LibConstants.PROJECT_FEE_BIPS] = 100; // 1%
    s.settings.i[LibConstants.STAKING_FEE_BIPS] = 100; // 5%
    s.settings.a[LibConstants.AUTHORIZED_SIGNER_WALLET] = msg.sender;
    s.settings.a[LibConstants.PROJECT_WALLET] = msg.sender;

    // deploy erc20 token
    address token = LibERC20.deployToken("WarMosaic", "MOSAIC");
    s.settings.a[LibConstants.MOSAIC_TOKEN] = msg.sender;

    emit InitializeDiamond(msg.sender);
  }
}
