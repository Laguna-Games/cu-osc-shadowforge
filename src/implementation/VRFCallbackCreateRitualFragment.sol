// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract VRFCallbackCreateRitualFragment {
    /// @notice Callback for VRF fulfillRandomness
    /// @dev This method MUST check `LibRNG.rngReceived(nonce)`
    /// @dev For multiple RNG callbacks, copy and rename this function
    /// @custom:see https://gb-docs.supraoracles.com/docs/vrf/v2-guide
    /// @param nonce The vrfRequestId
    /// @param rngList The random numbers
    function fulfillCreateRitualRandomness(uint256 nonce, uint256[] calldata rngList) external {}
}
