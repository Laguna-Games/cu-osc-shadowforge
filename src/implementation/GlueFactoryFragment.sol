// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract GlueFactoryFragment {
    event BatchSacrificeUnicorns(uint256[] tokenIds, address user);

    function batchSacrificeUnicorns(uint256[] memory tokenIds) external {}

    function setUnicornSoulsPoolId(uint256 poolId) external {}

    function getUnicornSoulsPoolId() external view returns (uint256 poolId) {}

    function setMaxBatchSacrificeUnicornsAmount(uint256 maxBatchAmount) external {}

    function getMaxBatchSacrificeUnicornsAmount() external view returns (uint256 maxBatchAmount) {}
}
