// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { IERC20Facet } from "../interfaces/IERC20Facet.sol";
import { ERC20Token } from "../shared/Structs.sol";
import { LibERC20 } from "../libs/LibERC20.sol";
import { AccessControl } from "../shared/AccessControl.sol";
import { LibAppStorage } from "../libs/LibAppStorage.sol";
import { LibString } from "../libs/LibString.sol";

error ERC20InvalidReceiver(address receiver);
error ERC20NotEnoughAllowance(address owner, address spender);

contract ERC20Facet is IERC20Facet, AccessControl {  
  /**
   * @dev Emitted when a token is approved for a spender.
   */
  event ERC20Approval(address token, address owner, address spender, uint256 value);

  function erc20Name(address token) external view returns (string memory) {
    return LibAppStorage.diamondStorage().erc20s[token].name;
  }

  function erc20Symbol(address token) external view returns (string memory) {
    return LibAppStorage.diamondStorage().erc20s[token].symbol;    
  }

  function erc20Decimals(address token) external view returns (uint8) {
    return LibAppStorage.diamondStorage().erc20s[token].decimals;
  }

  function erc20TotalSupply(address token) external view returns (uint256) {
    return LibAppStorage.diamondStorage().erc20s[token].totalSupply;
  }

  function erc20BalanceOf(address token, address account) external view returns (uint256) {
    return LibAppStorage.diamondStorage().erc20s[token].balances[account];
  }

  function erc20Allowance(address token, address account, address spender) external view returns (uint256) {
    return LibAppStorage.diamondStorage().erc20s[token].allowances[account][spender];
  }

  function erc20Approve(address token, address account, address spender, uint256 amount) external {
    LibAppStorage.diamondStorage().erc20s[token].allowances[account][spender] = amount;
    emit ERC20Approval(token, account, spender, amount);
  }

  function erc20Transfer(address token, address caller, address from, address to, uint256 amount) external {
    if (to == address(0)) {
      revert ERC20InvalidReceiver(to);
    }

    ERC20Token storage t = LibAppStorage.diamondStorage().erc20s[token];

    if (caller != from) {
      if (t.allowances[from][caller] < amount) {
        revert ERC20NotEnoughAllowance(from, caller);
      }

      t.allowances[from][caller] -= amount;
    }

    LibERC20.transfer(token, from, to, amount);
  }
}
