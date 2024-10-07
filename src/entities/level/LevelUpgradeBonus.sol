// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {LevelUpgradeBonusType} from './LevelUpgradeBonusType.sol';
import {LevelUpgradeBonusFrequency} from './LevelUpgradeBonusFrequency.sol';

/*
    @title Level Upgrade Bonus
    @notice This struct is used to define the upgrade bonus for each level
    @dev Examples of bonuses:
    +1 Dark Mark per hour
        bonusType = HUSK_GENERATION
        bonusValue = 1
        bonusFrequency = HOURLY
    +10 Husk storage cap
        bonusType = HUSK_STORAGE
        bonusValue = 10
        bonusFrequency = PERMANENT
*/
struct LevelUpgradeBonus {
    LevelUpgradeBonusType bonusType;
    uint256 bonusValue;
    LevelUpgradeBonusFrequency bonusFrequency;
}
