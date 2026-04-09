// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title PulseFeeNTickErrors
/// @notice Error definitions for PulseFeeNTickHook and related contracts.
library PulseFeeNTickErrors {
    error NotAdmin();
    error NotPoolManager();
    error NotTokenOwner();
    error AlreadyInitialized();
    error NotInitialized();
    error ContractPaused();
    error WrongPool();
    error RebalanceFailed();
    error ZeroShares();
    error FeeRefreshTooSoon();
    error InsufficientInventory();
}
