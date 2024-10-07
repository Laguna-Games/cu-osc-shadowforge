// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FarmingFragment} from "./FarmingFragment.sol";
import {GlueFactoryFragment} from "./GlueFactoryFragment.sol";
import {HatcheryRitualsFragment} from "./HatcheryRitualsFragment.sol";
import {LevelFragment} from "./LevelFragment.sol";
import {RewardsFragment} from "./RewardsFragment.sol";
import {StakingFragment} from "./StakingFragment.sol";
import {VRFCallbackCreateRitualFragment} from "./VRFCallbackCreateRitualFragment.sol";

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract CutShadowForgeDiamond is
    FarmingFragment,
    GlueFactoryFragment,
    HatcheryRitualsFragment,
    LevelFragment,
    RewardsFragment,
    StakingFragment,
    VRFCallbackCreateRitualFragment
{
    event GasReturnedToUser(
        uint256 amountReturned,
        uint256 txPrice,
        uint256 gasSpent,
        address indexed user,
        bool indexed success,
        string indexed transactionType
    );
    event GasReturnerMaxGasReturnedPerTransactionChanged(
        uint256 oldMaxGasReturnedPerTransaction,
        uint256 newMaxGasReturnedPerTransaction,
        address indexed admin
    );
    event GasReturnerInsufficientBalance(
        uint256 txPrice,
        uint256 gasSpent,
        address indexed user,
        string indexed transactionType
    );
}
