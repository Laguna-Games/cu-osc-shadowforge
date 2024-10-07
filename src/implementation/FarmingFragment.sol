// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibStructs} from '../libraries/LibStructs.sol';

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract FarmingFragment {
    event FarmableItemRegistered(
        address indexed admin,
        uint256 farmableItemId,
        uint256 poolId,
        uint256 hourlyRate,
        uint256 cap,
        string indexed uri
    );
    event FarmableItemModified(
        address indexed admin,
        uint256 farmableItemId,
        uint256 poolId,
        uint256 hourlyRate,
        uint256 cap,
        uint256 class,
        uint256 stat
    );

    event FarmableItemActivated(address indexed admin, uint256 farmableItemId);
    event FarmableItemDeactivated(address indexed admin, uint256 farmableItemId);
    event FarmableItemDeleted(address indexed admin, uint256 farmableItemId);

    /// Setup a new item for yield farming by the Shadowcorns.
    /// @param poolId - Terminus pool (Shadowcorns item collection only)
    /// @param hourlyRate - Number of items created in one batch per hour (3 decimals)
    /// @param cap - Max number of items that can be farmed per session
    /// @param class - Class of the Shadowcorn
    /// @param stat - Stat of the Shadowcorn to check when farming
    /// @param receivesHatcheryLevelBonus - Whether the item receives a bonus based on the hatchery level
    /// @param receivesRarityBonus - Whether the item receives a bonus based on the rarity of the minion
    function registerNewFarmableItem(
        uint256 poolId,
        uint256 hourlyRate,
        uint256 cap,
        uint256 class,
        uint256 stat,
        bool receivesHatcheryLevelBonus,
        bool receivesRarityBonus
    ) external {}

    /// Change the details of a farmableItem
    /// @param farmableItemId - Item to modify
    /// @param hourlyRate - Number of items created in one batch per hour (3 decimals)
    /// @param cap - Max number of items that can be farmed per session
    /// @param receivesHatcheryLevelBonus - Whether the item receives a bonus based on the hatchery level
    /// @param receivesRarityBonus - Whether the item receives a bonus based on the rarity of the minion
    function modifyFarmableItem(
        uint256 farmableItemId,
        uint256 poolId,
        uint256 hourlyRate,
        uint256 cap,
        uint256 class,
        uint256 stat,
        bool receivesHatcheryLevelBonus,
        bool receivesRarityBonus
    ) external {}

    /// Turn on a Farmable item for use
    function activateFarmableItem(uint256 farmableItemId) external {}

    /// Turn off a Farmable item for use
    function deactivateFarmableItem(uint256 farmableItemId) external {}

    /// Returns a list of Farmable items that are currently active.
    function getActiveFarmables() external view returns (LibStructs.FarmableItem[] memory, uint256[] memory) {}

    /// Returns the number of FarmableItem objects registered
    function getFarmableItemCount() external view returns (uint256) {}

    function getActiveFarmableCount() external view returns (uint256) {}

    function getFarmableItemData(uint256 farmableItemId) external view returns (LibStructs.FarmableItem memory) {}

    /// @notice Retrieves the total husks from the LibFarming contract.
    /// @return totalHusks The total number of husks.
    function getTotalHusks() external view returns (uint256 totalHusks) {}

    /// @notice Retrieves the total minions from the LibFarming contract.
    /// @return totalMinions The total number of minions.
    function getTotalMinions() external view returns (uint256 totalMinions) {}

    /// @notice Sets the husk pool IDs with the provided array of IDs.
    /// @dev Only the contract owner can call this function.
    /// @param _huskPoolIds An array of husk pool IDs to be added.
    function setHuskPoolIds(uint256[] memory _huskPoolIds) external {}

    /// @notice Retrieves the husk pool IDs.
    /// @return huskPoolIds An array of husk pool IDs.
    function getHuskPoolIds() external view returns (uint256[] memory huskPoolIds) {}

    /// @notice Sets the minion pool IDs with the provided array of IDs.
    /// @dev Only the contract owner can call this function.
    /// @param _minionPoolIds An array of minion pool IDs to be added.
    function setMinionPoolIds(uint256[] memory _minionPoolIds) external {}

    /// @notice Removes a specific minion pool ID.
    /// @dev Only the contract owner can call this function.
    /// @param _minionPoolId The ID of the minion pool to be removed.
    function removeMinionPoolId(uint256 _minionPoolId) external {}

    /// @notice Removes a specific husk pool ID.
    /// @dev Only the contract owner can call this function.
    /// @param _huskPoolId The ID of the husk pool to be removed.
    function removeHuskPoolId(uint256 _huskPoolId) external {}

    /// @notice Retrieves the minion pool IDs.
    /// @return minionPoolIds An array of minion pool IDs.
    function getMinionPoolIds() external view returns (uint256[] memory minionPoolIds) {}
}
