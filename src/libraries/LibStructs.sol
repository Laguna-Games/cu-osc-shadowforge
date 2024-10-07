// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

library LibStructs {
    struct StakeData {
        address staker; //  Address of the staker
        bool staked; //  TRUE if the stake is active
        uint256 farmableItemId; //  Id of the FarmableItem being farmed
        uint256 stakeTimestamp; //  Timestamp of the stake
    }

    /// Definition of a Terminus pool that can be yield farmed by Shadowcorns
    struct FarmableItem {
        bool active; /// TRUE if the item can be farmed
        uint256 poolId; /// Id of the pool on Terminus contract
        uint256 hourlyRate; /// how many of the items are made per hour (3 decimals)
        uint256 cap; /// max number that can be farmed per session
        string uri; /// passthrough from Terminus
        uint256 class; /// class of the shadowcorn
        uint256 stat; /// stat of the shadowcorn to use
        bool receivesHatcheryLevelBonus;
        bool receivesRarityBonus;
    }
}
