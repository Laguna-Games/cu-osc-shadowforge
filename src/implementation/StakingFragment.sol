// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibStructs} from '../libraries/LibStructs.sol';
import {LevelFullInfo} from '../entities/level/LevelFullInfo.sol';

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract StakingFragment {
    event ShadowcornStaked(
        uint256 indexed tokenId,
        address indexed staker,
        bool staked,
        uint256 farmableItemId,
        uint256 stakeTimestamp
    );

    event SetShadowcornFarmingData(
        address indexed player,
        uint256 indexed tokenId,
        LibStructs.FarmableItem farmingData
    );

    event ShadowcornUnstaked(
        uint256 indexed tokenId,
        address indexed staker,
        bool staked,
        uint256 farmableItemId,
        uint256 stakedTime
    );

    event ForcedUnstakeExecuted(address indexed player, uint256 indexed tokenId);

    event ShadowcornHarvest(
        address indexed player,
        uint256 indexed tokenId,
        uint256 indexed poolId,
        uint256 stakingRewards
    );

    /// Transfer a Shadowcorn into the Hatchery contract to begin yield farming.
    /// @param tokenId - The NFT to transfer
    /// @param farmableItemId - Id for the product to farm
    /// @custom:emits Transfer, ShadowcornStaked
    function stakeShadowcorn(uint256 tokenId, uint256 farmableItemId) external {}

    /// @notice Get staked shadowcorns by user
    /// @dev the first page is 0
    /// @return stakedShadowcorns - Array of staked shadowcorns
    function getStakedShadowcornsByUser(
        address user,
        uint32 _pageNumber
    ) external view returns (uint256[] memory stakedShadowcorns, bool moreEntriesExist) {}

    //  Unstake a Shadowcorn, transfer it back to the owner's wallet, and collect
    //  any goods that have been farmed. Progress toward incomplete items are lost.
    //  @param tokenId - The NFT to unstake
    //  @custom:emits Transfer, ShadowcornUnstaked, ShadowcornHarvest
    function unstakeShadowcorn(uint256 tokenId) external {}

    //  Collect any goods that have been farmed by a Shadowcorn, and immediately
    //  re-stake the Shadowcorn back to yield farming. Progress toward incomplete
    //  items is carried over.
    //  @param tokenId - The NFT to unstake
    //  @custom:emits ShadowcornHarvest
    function harvestAndRestake(uint256 tokenId) external {}

    //  Transfer a Shadowcorn back to the owner immediately.
    //  No yields are rewarded.
    //  @custom:emits Transfer
    function forceUnstake(uint256 tokenId) external {}

    function calculateFarmingBonus(
        uint256 tokenId,
        uint256 farmableItemId
    ) external view returns (LibStructs.FarmableItem memory shadowcornFarmingData) {}

    /// @notice Sets the cumulative husk limit for a given hatchery level
    /// @param hatcheryLevel - The hatchery level
    /// @param cumulativeHuskLimit - The cumulative husk limit
    /// @dev the limit should be set times * 100: example: if the limit is meant to be 0.2, the value should be set to 20.
    function setHatcheryLevelHuskLimitCumulative(uint256 hatcheryLevel, uint256 cumulativeHuskLimit) external {}

    /// @notice Gets the cumulative husk limit for a given hatchery level
    /// @return cumulativeHuskLimit - The cumulative husk limit
    function getHatcheryLevelHuskLimitCumulative(
        uint256 hatcheryLevel
    ) external view returns (uint256 cumulativeHuskLimit) {}

    /// @notice Gets the cumulative staking bonus for a given hatchery level
    /// @param hatcheryLevel - The hatchery level
    function getHatcheryLevelCumulativeBonus(uint256 hatcheryLevel) external view returns (uint256) {}

    function setHatcheryLevelCumulativeBonus(uint256 hatcheryLevel, uint256 cumulativeBonus) external {}

    function calculateStakingRewards(uint256 tokenId) external view returns (uint256 stakingReward) {}

    /// @notice Computes the time remaining until the cap is reached for a given token
    /// @param tokenId The ID of the token for which to calculate the time
    /// @return timeToReachCap The time remaining, in seconds, until the cap is reached
    function computeTimeToReachCap(uint256 tokenId) external view returns (uint256 timeToReachCap) {}

    /// @notice Computes the time remaining until the next husk is created for a given token
    /// @param tokenId The ID of the token for which to calculate the time
    /// @return timeUntilNextHusk The time remaining, in seconds, until the next husk is created
    function getTimeUntilNextHusk(uint256 tokenId) external view returns (uint256 timeUntilNextHusk) {}

    /// @notice Retrieves staking details including the husks created, time to reach cap, cap amount, and time until next husk
    /// @param tokenId The ID of the token for which to retrieve the details
    /// @return husksCreated The number of husks created since staking
    /// @return timeToReachCap The time remaining, in hours, until the cap is reached
    /// @return capAmount The cap amount, divided by 1000
    /// @return timeUntilNextHusk The time remaining, in seconds, until the next husk is created
    function getStakingDetails(
        uint256 tokenId
    )
        external
        view
        returns (uint256 husksCreated, uint256 timeToReachCap, uint256 capAmount, uint256 timeUntilNextHusk)
    {}

    /// @notice Retrieves the staking information for a specific Shadowcorn token
    /// @param tokenId The ID of the Shadowcorn token for which to retrieve the staking information
    /// @return A LibStructs.StakeData struct containing the staking details for the specified token
    function getStakingInfoByShadowcornId(uint256 tokenId) external view returns (LibStructs.StakeData memory) {}

    function getFarmingBonusBreakdown(
        uint256 tokenId
    ) external view returns (uint256 baseRate, uint256 hatcheryLevelBonus, uint256 classBonus, uint256 rarityBonus) {}

    function getFarmingRateByFarmableItems(
        uint256 tokenId,
        uint256[] memory farmableItemIds
    ) external view returns (uint256[] memory) {}

    function getFarmingHusksPerHour(
        uint256 tokenId
    )
        external
        view
        returns (uint256 fireHusks, uint256 slimeHusks, uint256 voltHusks, uint256 soulHusks, uint256 nebulaHusks)
    {}

    /// @notice Get farmable item by shadowcorn id
    /// @param shadowcornId The shadowcorn id to get the farmable item for
    /// @return farmableItem The farmable item
    function getFarmableItemByShadowcornId(
        uint256 shadowcornId
    ) external view returns (LibStructs.FarmableItem memory farmableItem) {}

    /// @notice Get levels unlockCosts, cumulativeBonus, and cumulativeHuskLimit paginated (5 levels per page)
    /// @param page The page number to retrieve
    /// @return LevelFullInfo[] The levels info
    function getHatcheryLevelsFullInfo(uint8 page) external view returns (LevelFullInfo[5] memory) {}
}
