// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ERC20 } from "../facades/ERC20.sol";
import { ERC20Token } from "../shared/Structs.sol";
import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";

error ERC20NotEnoughBalance(address sender);

library LibERC20 {
  /**
   * @dev Emitted when a token is minted.
   */
  event ERC20Minted(address token, address to, uint256 amount);
  /**
   * @dev Emitted when a token is burned.
   */
  event ERC20Burned(address token, address from, uint256 amount);
  /**
   * @dev Emitted when a token is transferred.
   */
  event ERC20Transferred(address token, address from, address to, uint256 value);
  /**
   * @dev Emitted when a new token is deployed.
   */
  event ERC20NewToken(address token);

  /**
   * @dev Deploy new token.
   * 
   * @param name The name of the token.
   * @param symbol The symbol of the token.
   */
  function deployToken(string memory name, string memory symbol) internal returns (address) {
    address token = address(new ERC20(address(this)));

    ERC20Token storage t = LibAppStorage.diamondStorage().erc20s[token];
    t.name = name;
    t.symbol = symbol;
    t.decimals = 18;

    emit ERC20NewToken(token);

    return token;
  }

  /**
    * @dev Transfer a token.
    *
    * @param token The token to transfer.
    * @param from The address to transfer the token from.
    * @param to The address to transfer the token to.
    * @param amount The amount to transfer.
    */
  function transfer(address token, address from, address to, uint256 amount) internal {
    ERC20Token storage t = LibAppStorage.diamondStorage().erc20s[token];

    if (amount > t.balances[from]) {
      revert ERC20NotEnoughBalance(from);
    }

    unchecked {
      t.balances[from] -= amount;
      t.balances[to] += amount;      
    }

    emit ERC20Transferred(token, from, to, amount);
  }

  /**
    * @dev Mint a token.
    *
    * @param token The token to mint.
    * @param to The address to mint the token to.
    * @param amount The amount to mint.
    */
  function mint(address token, address to, uint256 amount) internal {
    ERC20Token storage t = LibAppStorage.diamondStorage().erc20s[token];
    t.totalSupply += amount;
    t.balances[to] += amount;

    emit ERC20Minted(token, to, amount);
  }  

  /**
    * @dev Burn a token.
    *
    * @param token The token to burn.
    * @param from The address to burn the token from.
    * @param amount The amount to burn.
    */
  function burn(address token, address from, uint256 amount) internal {
    ERC20Token storage t = LibAppStorage.diamondStorage().erc20s[token];
    if (t.balances[from] < amount) {
      revert ERC20NotEnoughBalance(from);
    }
    unchecked {
      t.totalSupply -= amount;
      t.balances[from] -= amount;
    }

    emit ERC20Burned(token, from, amount);
  }  
}
