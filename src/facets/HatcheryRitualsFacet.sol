// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IRitualFacet} from "../../lib/cu-osc-common/src/interfaces/IRitualFacet.sol";
import {LibHatcheryRituals} from "../libraries/LibHatcheryRituals.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibHatcheryRitualComponents} from "../libraries/LibHatcheryRitualComponents.sol";
import {LibHatcheryRitualConstraints} from "../libraries/LibHatcheryRitualConstraints.sol";
import {LibRitualComponents} from "../../lib/cu-osc-common/src/libraries/LibRitualComponents.sol";
import {LibConstraints} from "../../lib/cu-osc-common/src/libraries/LibConstraints.sol";
import {LibGasReturner} from "../../lib/cu-osc-common/src/libraries/LibGasReturner.sol";

contract HatcheryRitualsFacet {
    // @notice This function is used to consume a ritual charge.
    // @param ritualId The id of the ritual to consume a charge from.
    function consumeRitualCharge(uint256 ritualId) external {
        LibHatcheryRituals.consumeRitualCharge(ritualId);
    }

    function batchConsumeRitualCharges(uint256[] memory ritualIds) external {
        uint256 availableGas = gasleft();
        require(
            ritualIds.length > 0 &&
                ritualIds.length <= LibHatcheryRituals.getMaxRitualsPerBatch(),
            "HatcheryRitualsFacet: Ensure rituals count is within 1 to max batch size."
        );

        for (uint256 i = 0; i < ritualIds.length; i++) {
            LibHatcheryRituals.consumeRitualCharge(ritualIds[i]);
        }
        LibGasReturner.returnGasToUser(
            "batchConsumeRitualCharges",
            (availableGas - gasleft()),
            payable(msg.sender)
        );
    }

    function setMaxRitualsPerBatch(uint256 maxRitualsPerBatch) external {
        LibContractOwner.enforceIsContractOwner();
        LibHatcheryRituals.setMaxRitualsPerBatch(maxRitualsPerBatch);
    }

    function getMaxRitualsPerBatch()
        external
        view
        returns (uint256 maxRituals)
    {
        return LibHatcheryRituals.getMaxRitualsPerBatch();
    }

    function canConsumeRitual(
        uint256 ritualId,
        address user
    ) external view returns (bool canConsume) {
        return LibHatcheryRituals.canConsumeRitual(ritualId, user);
    }

    function createRitual(uint256 ritualTemplatePoolId) external {
        uint256 availableGas = gasleft();
        LibHatcheryRituals.createRitual(ritualTemplatePoolId);
        LibGasReturner.returnGasToUser(
            "createRitual",
            (availableGas - gasleft()),
            payable(msg.sender)
        );
    }

    function getRitualTemplateById(
        uint256 ritualTemplateId
    )
        external
        view
        returns (LibHatcheryRituals.RitualTemplate memory ritualTemplate)
    {
        return LibHatcheryRituals.getRitualTemplateById(ritualTemplateId);
    }

    function removeAffixFromBucket(uint256 affixId, uint256 bucketId) external {
        LibContractOwner.enforceIsContractOwner();
        LibHatcheryRituals.removeAffixFromBucket(affixId, bucketId);
    }

    function addAffixesToBucket(
        uint256[] memory affixesIds,
        uint256 bucketId
    ) external {
        LibContractOwner.enforceIsContractOwner();
        LibHatcheryRituals.addAffixesToBucket(affixesIds, bucketId);
    }

    function createAffix(
        LibHatcheryRituals.Affix memory affix
    ) external returns (uint256 id) {
        LibContractOwner.enforceIsContractOwner();
        return LibHatcheryRituals.createAffix(affix);
    }

    function addRitualTemplateToPool(
        uint256 ritualTemplateId,
        uint256 ritualPoolId,
        uint256 rngWeight
    ) external {
        LibContractOwner.enforceIsContractOwner();
        LibHatcheryRituals.addRitualTemplateToPool(
            ritualTemplateId,
            ritualPoolId,
            rngWeight
        );
    }

    function createRitualTemplatePool(
        LibRitualComponents.RitualCost[] memory creationCosts,
        LibConstraints.Constraint[] memory creationConstraints
    ) external returns (uint256 id) {
        LibContractOwner.enforceIsContractOwner();
        return
            LibHatcheryRituals.createRitualTemplatePool(
                creationCosts,
                creationConstraints
            );
    }

    function createRitualTemplate(
        LibHatcheryRituals.RitualTemplate memory template
    ) external returns (uint256 id) {
        LibContractOwner.enforceIsContractOwner();
        return LibHatcheryRituals.createRitualTemplate(template);
    }

    function getCreationConstraintsAndCosts(
        uint256 ritualTemplatePoolId
    )
        external
        view
        returns (
            LibConstraints.Constraint[] memory constraints,
            LibRitualComponents.RitualCost[] memory costs
        )
    {
        return
            LibHatcheryRituals.getCreationConstraintsAndCosts(
                ritualTemplatePoolId
            );
    }

    function createAffixBucket(uint256[] memory affixIds) external {
        LibContractOwner.enforceIsContractOwner();
        LibHatcheryRituals.createAffixBucket(affixIds);
    }
}
