// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibStructs} from "../libraries/LibStructs.sol";
import {LibHatcheryRituals} from "../libraries/LibHatcheryRituals.sol";
import {LibRitualComponents} from "../../lib/cu-osc-common/src/libraries/LibRitualComponents.sol";
import {LibConstraints} from "../../lib/cu-osc-common/src/libraries/LibConstraints.sol";

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract DebugFragment {
    // Function is called when creating minions using recipes
    function debugAddToQueue(uint256 quantity, address user) external {}

    function debugBeginNewWave() external {}

    function debugGetWaveTime() external view returns (uint256) {}

    function debugGetShadowcornFarmingRate(
        uint256 tokenId
    ) external view returns (uint256) {}

    function debugResetHatcheryLevel(address user) external {}

    function debugSetHatcheryLevel(address user, uint256 level) external {}

    /// @notice Returns the shadowcorn from the hatchery to the owner
    function debugReturnShadowcorn(uint256 tokenId, address user) external {}

    function debugResetStakingData(uint256 tokenId) external {}

    function debugResetStakedArray(address user) external {}

    function debugCalculateStakingRewards(
        uint256 tokenId
    ) external view returns (uint256) {}

    function debugCalculatePreCapStakingRewards(
        uint256 tokenId
    ) external view returns (uint256) {}

    function debugCalculateTimeSinceStaking(
        uint256 tokenId
    ) external view returns (uint256) {}

    function debugGetStakeData(
        uint256 tokenId
    ) external view returns (LibStructs.StakeData memory) {}

    function debugGetFarmingData(
        uint256 tokenId
    ) external view returns (LibStructs.FarmableItem memory) {}

    function debugGetRitualTemplatePoolQuantity()
        external
        view
        returns (uint256)
    {}

    function debugGetRitualTemplateIdsByPoolId(
        uint256 ritualTemplatePoolId
    ) external view returns (uint256[] memory) {}

    function debugGetRitualTemplate(
        uint256 ritualTemplateId
    ) external view returns (LibHatcheryRituals.RitualTemplate memory) {}

    function getAffixBucketQuantity() external view returns (uint256) {}

    function getAffixIdsByAffixBucketId(
        uint256 affixBucketId
    ) external view returns (uint256[] memory) {}

    function getAffix(
        uint256 affixId
    ) external view returns (LibHatcheryRituals.Affix memory) {}

    function getCreationCostsAndConstraintsByTemplatePoolId(
        uint256 ritualTemplatePoolId
    )
        external
        view
        returns (
            LibRitualComponents.RitualCost[] memory,
            LibConstraints.Constraint[] memory
        )
    {}

    function debugUpdateCostAffix(
        uint256 affixId,
        uint256 componentAmount,
        uint128 componentAssetType,
        uint128 componentPoolId,
        address componentAsset,
        LibRitualComponents.RitualCostTransferType costTransferType
    ) external {}

    function debugUpdateProductAffix(
        uint256 affixId,
        uint256 componentAmount,
        uint128 componentAssetType,
        uint128 componentPoolId,
        address componentAsset,
        LibRitualComponents.RitualProductTransferType productTransferType
    ) external {}

    function debugUpdatePoolIdForAffixesCosts(
        uint256[] memory affixIds,
        uint128 componentPoolId
    ) external {}

    function debugUpdatePoolIdForTemplatesCosts(
        uint256[] memory templateIds,
        uint128 costIndex,
        uint128 componentPoolId
    ) external {}

    function debugApplyAffix(
        LibHatcheryRituals.RitualTemplate memory ritualTemplate,
        LibHatcheryRituals.Affix memory affix
    )
        external
        view
        returns (
            LibHatcheryRituals.RitualTemplate memory,
            bool shouldEmitWarning,
            string memory warningMessage
        )
    {}

    function debugSetControllerForShadowcornItems(
        address newController
    ) external {}

    function debugSetWhitelistedToCreateRitual(
        address user,
        bool whitelisted
    ) external {}

    function debugGetWhitelistedToCreateRitual(
        address user
    ) external view returns (bool) {}

    // function debugStartCreateRitual(uint256 ritualTemplatePoolId) external {}

    // function debugFinishCreateRitual(uint256 ritualTemplateId, uint256 randomness) external {}

    function debugEmptyPlayerAndGlobalQueue(address user) external {}

    // function resetFarmableItems() external {}

    function debugUpdateAffixTypeByAffixId(
        uint256 affixId,
        LibHatcheryRituals.AffixType affixType
    ) external {}

    // function debugBurnUnim(uint256 amount) external {}
}
