// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {LevelUnlockCost} from './LevelUnlockCost.sol';

struct LevelFullInfo {
    LevelUnlockCost[] unlockCosts;
    uint256 cumulativeBonus;
    uint256 cumulativeHuskLimit;
    uint256 hatcheryLevel;
}
