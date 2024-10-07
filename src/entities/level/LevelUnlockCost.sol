// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Component} from '../common/Component.sol';
import {LevelUnlockCostTokenTransferType} from './LevelUnlockCostTokenTransferType.sol';

/*
    @title Level Unlock Cost
    @notice This struct is used to define the cost of unlocking each level
    @param component The component that is required to unlock the level
    @param transferType The type of transfer that will be used for the cost (BURN, TRANSFER)
 */
struct LevelUnlockCost {
    Component component;
    LevelUnlockCostTokenTransferType transferType;
}
