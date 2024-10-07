// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibHatcheryRituals} from "../libraries/LibHatcheryRituals.sol";
import {LibRitualComponents} from "../../lib/cu-osc-common/src/libraries/LibRitualComponents.sol";
import {LibConstraints} from "../../lib/cu-osc-common/src/libraries/LibConstraints.sol";

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract HatcheryRitualsFragment {
    event RitualTemplateCreated(uint256 indexed id);
    event RitualTemplatePoolCreated(uint256 indexed id);
    event AffixCreated(uint256 indexed id);
    event AffixBucketCreated(uint256 indexed id, uint256[] affixIds);
    event BeginRitualCreation(
        address indexed playerWallet,
        uint256 indexed ritualTemplatePoolId,
        uint256 indexed vrfRequestId
    );
    event FinishRitualCreation(
        uint256 indexed vrfRequestId,
        uint256 ritualTemplateId,
        uint256 indexed ritualTokenId,
        uint256[] affixIdsApplied,
        address indexed user
    );

    event HatcheryAffixWarning(string warningText);

    // @notice This function is used to consume a ritual charge.
    // @param ritualId The id of the ritual to consume a charge from.
    function consumeRitualCharge(uint256 ritualId) external {}

    function batchConsumeRitualCharges(uint256[] memory ritualIds) external {}

    function setMaxRitualsPerBatch(uint256 maxRitualsPerBatch) external {}

    function getMaxRitualsPerBatch()
        external
        view
        returns (uint256 maxRituals)
    {}

    function canConsumeRitual(
        uint256 ritualId,
        address user
    ) external view returns (bool canConsume) {}

    function createRitual(uint256 ritualTemplatePoolId) external {}

    function getRitualTemplateById(
        uint256 ritualTemplateId
    )
        external
        view
        returns (LibHatcheryRituals.RitualTemplate memory ritualTemplate)
    {}

    function removeAffixFromBucket(
        uint256 affixId,
        uint256 bucketId
    ) external {}

    function addAffixesToBucket(
        uint256[] memory affixesIds,
        uint256 bucketId
    ) external {}

    function createAffix(
        LibHatcheryRituals.Affix memory affix
    ) external returns (uint256 id) {}

    function addRitualTemplateToPool(
        uint256 ritualTemplateId,
        uint256 ritualPoolId,
        uint256 rngWeight
    ) external {}

    function createRitualTemplatePool(
        LibRitualComponents.RitualCost[] memory creationCosts,
        LibConstraints.Constraint[] memory creationConstraints
    ) external returns (uint256 id) {}

    function createRitualTemplate(
        LibHatcheryRituals.RitualTemplate memory template
    ) external returns (uint256 id) {}

    function getCreationConstraintsAndCosts(
        uint256 ritualTemplatePoolId
    )
        external
        view
        returns (
            LibConstraints.Constraint[] memory constraints,
            LibRitualComponents.RitualCost[] memory costs
        )
    {}

    function createAffixBucket(uint256[] memory affixIds) external {}
}
