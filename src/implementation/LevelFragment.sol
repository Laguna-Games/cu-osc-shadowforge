// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LevelUnlockCost} from '../entities/level/LevelUnlockCost.sol';

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract LevelFragment {
    event HatcheryLevelUnlocked(address indexed player, uint256 oldLevel, uint256 newLevel);

    /// @notice This function is used to get the current hatchery level for the sender address
    /// @param _user The address to get the hatchery level for
    /// @return uint256 The current hatchery level for the sender address (1 if not initialized)
    function getHatcheryLevel(address _user) external view returns (uint256) {}

    /// @dev Unlock the next hatchery level
    /// @notice This function is used to unlock the next hatchery level for an address if it's available
    function unlockNextHatcheryLevel() external {}

    /// @dev Get hatchery level unlocking costs
    /// @notice This function is used to get the costs for unlocking an specific level
    /// @param _hatcheryLevel The level to get the costs for
    /// @return LevelUnlockCost[] The costs for unlocking the level
    function getHatcheryLevelUnlockCosts(uint256 _hatcheryLevel) external view returns (LevelUnlockCost[] memory) {}

    /// @dev Add a cost for a hatchery level
    /// @notice This function is used to add a cost to an specific level
    /// @dev This function can only be called by the contract owner
    /// @param _hatcheryLevel The level to set the cost for
    /// @param _transferType The type of transfer that will be used for the cost (BURN, TRANSFER)
    /// @param _amount The amount of the cost
    /// @param _assetType The type of asset that will be used for the cost (0: ERC20, 1: ERC1155, 2: ERC721)
    /// @param _asset The asset of the cost
    /// @param _poolId The pool id of the cost (0 if the asset is not ERC1155/Terminus)
    function addHatcheryLevelUnlockCost(
        uint256 _hatcheryLevel,
        uint256 _transferType,
        uint128 _amount,
        uint128 _assetType,
        address _asset,
        uint256 _poolId
    ) external {}

    /// @dev Set hatchery level unlocking costs
    /// @notice This function is used to set the costs for unlocking an specific level
    /// @dev The arrays must be the same length
    /// @dev This function can only be called by the contract owner
    /// @dev When setting the costs for an specific level, the previous costs will be deleted
    /// @dev There are multiple parallel arrays instead of a single array to prevent big nested structs array.
    /// @param _hatcheryLevel The level to set the costs for
    /// @param _transferTypes The types of transfer that will be used for the cost (BURN, TRANSFER)
    /// @param _amounts The amounts of the costs
    /// @param _assetTypes The types of asset that will be used for the costs (0: ERC20, 1: ERC1155, 2: ERC721)
    /// @param _assets The assets of the costs
    /// @param _poolIds The pool ids of the costs (0 if the asset is not ERC1155/Terminus)
    function setHatcheryLevelUnlockCosts(
        uint256 _hatcheryLevel,
        uint256[] memory _transferTypes,
        uint128[] memory _amounts,
        uint128[] memory _assetTypes,
        address[] memory _assets,
        uint256[] memory _poolIds
    ) external {}

    /// @dev Get the hatchery level cap
    /// @notice This function is used to get the level cap for all the hatcheries
    /// @return uint256 The level cap for all the hatcheries
    function getHatcheryLevelCap() external view returns (uint256) {}

    /// @dev Set the hatchery level cap
    /// @notice This function is used to set the level cap for all the hatcheries
    /// @dev This function can only be called by the contract owner
    /// @param _hatcheryLevelCap The level cap for all the hatcheries
    function setHatcheryLevelCap(uint256 _hatcheryLevelCap) external {}
}
