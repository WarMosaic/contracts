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
    LibSettings.setUint(LibConstants.GAME_CREATOR_FEE_BIPS, 300); // 3%
    LibSettings.setUint(LibConstants.REFERER_FEE_BIPS, 100); // 1%
    LibSettings.setUint(LibConstants.PROJECT_FEE_BIPS, 100); // 1%
    LibSettings.setUint(LibConstants.STAKING_FEE_BIPS, 100); // 5%

    // deploy erc20 token
    address token = LibERC20.deployToken("WarMosaic", "MOSAIC");
    LibSettings.setAddress(LibConstants.MOSAIC_TOKEN, token);

    emit InitializeDiamond(msg.sender);
  }
}
