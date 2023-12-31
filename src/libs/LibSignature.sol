// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { SignatureChecker } from "lib/openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import { LibSettings } from "./LibSettings.sol";
import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { LibErrors } from "./LibErrors.sol";

error SignatureInvalid(string reason);

library LibSignature {
  function assertBySigner(bytes32 sigHash, bytes memory signature, address signer, string memory reason) internal view {
    if (!SignatureChecker.isValidSignatureNow(signer, sigHash, signature)) {
      revert SignatureInvalid(reason);
    }
  }

  function assertByAuthorizedSigner(bytes32 sigHash, bytes memory signature) internal view {
    address signer = LibSettings.getAuthorizedSignerWallet();
    LibSignature.assertBySigner(sigHash, signature, signer, "auth");
  }

  // prevents replay attacks if deadline is still valid
  function assertSignedHash(bytes32 sigHash) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    if(s.signedHashes[sigHash]) {
      revert LibErrors.InvalidatedSigHash();
    }
    s.signedHashes[sigHash] = true;
  }
}
