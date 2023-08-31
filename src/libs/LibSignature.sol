// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { SignatureChecker } from "lib/openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import { LibSettings } from "./LibSettings.sol";

error SignatureInvalid(string reason);

library LibSignature {
  function assertBySigner(bytes32 sigHash, bytes memory signature, address signer, string memory reason) internal {
    if (!SignatureChecker.isValidSignatureNow(signer, sigHash, signature)) {
      revert SignatureInvalid(reason);
    }
  }

  function assertByAuthorizedSigner(bytes32 sigHash, bytes memory signature) internal {
    address signer = LibSettings.getAuthorizedSignerWallet();
    LibSignature.assertBySigner(sigHash, signature, signer, "auth");
  }
}
