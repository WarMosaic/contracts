// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { DiamondProxy } from "src/generated/DiamondProxy.sol";
import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";
import { LibDiamondHelper } from "src/generated/LibDiamondHelper.sol";
import { InitDiamond } from "src/init/InitDiamond.sol";

abstract contract TestBaseContract is Test {
  // use private key to enable signing with account0 (Auth Account)
  uint authAccountKey = 0xaa;
  address public immutable account0 = vm.addr(authAccountKey);
  address public account1;
  address public account2;

  IDiamondProxy public diamond;

  function setUp() public virtual {
    console2.log("\n -- Test Base\n");

    console2.log("Test contract address, aka account0", address(this));
    console2.log("msg.sender during setup", msg.sender);

    vm.label(account0, "Auth Account");
    account1 = vm.addr(1);
    vm.label(account1, "Account 1");
    account2 = vm.addr(2);
    vm.label(account2, "Account 2");

    console2.log("Deploy diamond");
    diamond = IDiamondProxy(address(new DiamondProxy(account0)));

    console2.log("Cut and init");
    IDiamondCut.FacetCut[] memory cut = LibDiamondHelper.deployFacetsAndGetCuts();
    InitDiamond init = new InitDiamond();
    vm.prank(account0);
    diamond.diamondCut(cut, address(init), abi.encodeWithSelector(init.init.selector));
  }

  function _get_players(uint playerCount) internal pure returns(address[] memory _players) {
    _players = new address[](playerCount);
    for(uint i=0; i<playerCount; ++i) {
        _players[i] = vm.addr(0xff + i);
    }
}

function _compute_sig(bytes32 hash_, uint key) internal view returns(bytes memory) {
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash_);
    return abi.encodePacked(r, s, v);
}
}
