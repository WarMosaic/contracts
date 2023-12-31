// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

library LibErrors {
    error AuthFailed();
    error SigExpired();
    error LengthMismatch();
    error InvalidatedSigHash();
}