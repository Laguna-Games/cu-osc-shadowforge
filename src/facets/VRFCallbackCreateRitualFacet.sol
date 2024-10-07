// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IVRFCallback} from "../../lib/cu-osc-common/src/interfaces/IVRFCallback.sol";
import {LibRNG} from "../../lib/cu-osc-common/src/libraries/LibRNG.sol";
import {LibHatcheryRituals} from "../libraries/LibHatcheryRituals.sol";

contract VRFCallbackCreateRitualFacet {
    /// @notice Callback for VRF fulfillRandomness
    /// @dev This method MUST check `LibRNG.rngReceived(nonce)`
    /// @dev For multiple RNG callbacks, copy and rename this function
    /// @custom:see https://gb-docs.supraoracles.com/docs/vrf/v2-guide
    /// @param nonce The vrfRequestId
    /// @param rngList The random numbers
    function fulfillCreateRitualRandomness(
        uint256 nonce,
        uint256[] calldata rngList
    ) external {
        LibRNG.rngReceived(nonce);
        LibHatcheryRituals.createRitualFulfillRandomness(nonce, rngList[0]);
    }
}
