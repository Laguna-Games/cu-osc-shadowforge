// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibHatcheryRitualConstraints} from "./LibHatcheryRitualConstraints.sol";
import {LibConstraints} from "../../lib/cu-osc-common/src/libraries/LibConstraints.sol";
import {LibHatcheryRitualComponents} from "./LibHatcheryRitualComponents.sol";
import {LibRitualComponents} from "../../lib/cu-osc-common/src/libraries/LibRitualComponents.sol";
import {LibConstraintOperator} from "../../lib/cu-osc-common/src/libraries/LibConstraintOperator.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {IRitualFacet} from "../../lib/cu-osc-common/src/interfaces/IRitualFacet.sol";
import {LibRNG} from "../../lib/cu-osc-common/src/libraries/LibRNG.sol";
import {LibRitualNames} from "./LibRitualNames.sol";
import {LibArray} from "./LibArray.sol";
import {LibRitualData} from "../../lib/cu-osc-common/src/libraries/LibRitualData.sol";
import {LibString} from "../../lib/cu-osc-common/src/libraries/LibString.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";

library LibHatcheryRituals {
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

    struct HatcheryRitualStorage {
        uint256 lastTemplateId;
        uint256 lastPoolId;
        uint256 lastAffixId;
        mapping(uint256 => BasicRitualTemplate) basicRitualTemplateByRitualTemplateId;
        mapping(uint256 => LibConstraints.Constraint[]) consumptionConstraintsByRitualTemplateId;
        mapping(uint256 => LibRitualComponents.RitualCost[]) consumptionCostsByRitualTemplateId;
        mapping(uint256 => LibRitualComponents.RitualProduct[]) consumptionProductsByRitualTemplateId;
        mapping(uint256 => LibConstraints.Constraint[]) creationConstraintsByTemplatePoolId;
        mapping(uint256 => LibRitualComponents.RitualCost[]) creationCostsByTemplatePoolId;
        mapping(uint256 => uint256[]) affixBucketIdsByRitualTemplateId;
        mapping(uint256 => uint256[]) ritualTemplateIdsByTemplatePoolId;
        mapping(uint256 => uint256[]) ritualTemplateWeightsByTemplatePoolId;
        mapping(uint256 => uint256) ritualTemplateSumWeightByTemplatePoolId;
        mapping(uint256 => Affix) affixById;
        mapping(uint256 => uint256[]) affixIdsByAffixBucketId;
        mapping(uint256 => uint256) ritualTemplatePoolIdByVRFRequestId;
        mapping(uint256 => address) playerWalletByVRFRequestId;
        uint256 lastAffixBucketId;
        uint256 maxRitualsPerBatch;
    }

    enum AffixType {
        NONE,
        COST,
        PRODUCT,
        CHARGES,
        CONSTRAINT,
        SOULBOUND
    }

    struct Affix {
        AffixType affixType;
        bool isPositive;
        uint256 charges;
        LibRitualComponents.RitualCost cost;
        LibRitualComponents.RitualProduct product;
        LibConstraints.Constraint constraint;
        uint256 weight;
    }

    struct BasicRitualTemplate {
        uint8 rarity;
        uint256 charges;
        bool soulbound;
    }

    struct RitualTemplate {
        uint8 rarity;
        uint256 charges;
        bool soulbound;
        uint256[] affixBucketIds;
        LibConstraints.Constraint[] consumptionConstraints;
        LibRitualComponents.RitualCost[] consumptionCosts;
        LibRitualComponents.RitualProduct[] consumptionProducts;
    }

    uint256 private constant SALT_1 = 1;
    uint256 private constant SALT_PER_BUCKET = 100000;

    string private constant CALLBACK_SIGNATURE =
        "fulfillCreateRitualRandomness(uint256,uint256[])";

    bytes32 private constant HATCHERY_RITUAL_STORAGE_POSITION =
        keccak256("CryptoUnicorns.HatcheryRitual.Storage");

    function hatcheryRitualStorage()
        internal
        pure
        returns (HatcheryRitualStorage storage ds)
    {
        bytes32 position = HATCHERY_RITUAL_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // @notice This function is used to check if the user meets the constraints of a ritual.
    // @param constraints The constraints of the ritual.
    function checkConstraints(
        LibConstraints.Constraint[] memory constraints,
        address user
    ) internal view {
        for (uint256 i = 0; i < constraints.length; i++) {
            //Max uint256 is used as a placeholder for the tokenId in the constraints.
            LibHatcheryRitualConstraints.checkConstraint(constraints[i], user);
        }
    }

    // @notice This function is used to pay the costs of a ritual.
    // @param costs The costs of the ritual.
    function payCosts(LibRitualComponents.RitualCost[] memory costs) internal {
        for (uint256 i = 0; i < costs.length; i++) {
            LibHatcheryRitualComponents.payCost(costs[i]);
        }
    }

    // @notice This function is used to mint the products of a ritual.
    // @param products The products of the ritual.
    function mintProducts(
        LibRitualComponents.RitualProduct[] memory products
    ) internal {
        for (uint256 i = 0; i < products.length; i++) {
            LibHatcheryRitualComponents.mintProduct(products[i]);
        }
    }

    function consumeRitualCharge(uint256 ritualId) internal {
        address ritualsAddress = LibResourceLocator.ritualNFT();
        LibRitualData.Ritual memory ritual = IRitualFacet(ritualsAddress)
            .validateChargesAndGetRitualDetailsForConsume(ritualId, msg.sender);
        checkConstraints(ritual.constraints, msg.sender);
        payCosts(ritual.costs);
        IRitualFacet(ritualsAddress).consumeRitualCharge(ritualId);
        mintProducts(ritual.products);
    }

    function canConsumeRitual(
        uint256 ritualId,
        address user
    ) internal view returns (bool canConsume) {
        address ritualsAddress = LibResourceLocator.ritualNFT();
        LibRitualData.Ritual memory ritual = IRitualFacet(ritualsAddress)
            .validateChargesAndGetRitualDetailsForConsume(ritualId, user);
        checkConstraints(ritual.constraints, user);
        return true;
    }

    function nextRitualTemplatePoolId() private returns (uint256) {
        return ++hatcheryRitualStorage().lastPoolId;
    }

    function nextRitualTemplateId() private returns (uint256) {
        return ++hatcheryRitualStorage().lastTemplateId;
    }

    function nextAffixId() private returns (uint256) {
        return ++hatcheryRitualStorage().lastAffixId;
    }

    function nextHatcheryBucketId() internal returns (uint256) {
        return ++hatcheryRitualStorage().lastAffixBucketId;
    }

    function setMaxRitualsPerBatch(uint256 maxRitualsPerBatch) internal {
        hatcheryRitualStorage().maxRitualsPerBatch = maxRitualsPerBatch;
    }

    function getMaxRitualsPerBatch() internal view returns (uint256) {
        return hatcheryRitualStorage().maxRitualsPerBatch;
    }

    function createBasicRitualTemplate(
        uint8 rarity,
        uint256 charges,
        bool soulbound
    ) internal returns (uint256 templateId) {
        HatcheryRitualStorage storage hrs = hatcheryRitualStorage();
        templateId = nextRitualTemplateId();

        hrs.basicRitualTemplateByRitualTemplateId[
            templateId
        ] = BasicRitualTemplate({
            rarity: rarity,
            charges: charges,
            soulbound: soulbound
        });
    }

    function createRitualTemplate(
        RitualTemplate memory template
    ) internal returns (uint256 id) {
        HatcheryRitualStorage storage hrs = hatcheryRitualStorage();
        id = nextRitualTemplateId();
        hrs.basicRitualTemplateByRitualTemplateId[id] = BasicRitualTemplate({
            rarity: template.rarity,
            charges: template.charges,
            soulbound: template.soulbound
        });

        for (uint256 i = 0; i < template.consumptionConstraints.length; ++i) {
            hrs.consumptionConstraintsByRitualTemplateId[id].push(
                template.consumptionConstraints[i]
            );
        }

        for (uint256 i = 0; i < template.consumptionCosts.length; ++i) {
            hrs.consumptionCostsByRitualTemplateId[id].push(
                template.consumptionCosts[i]
            );
        }

        for (uint256 i = 0; i < template.consumptionProducts.length; ++i) {
            hrs.consumptionProductsByRitualTemplateId[id].push(
                template.consumptionProducts[i]
            );
        }

        for (uint256 i = 0; i < template.affixBucketIds.length; ++i) {
            hrs.affixBucketIdsByRitualTemplateId[id].push(
                template.affixBucketIds[i]
            );
        }
        emit RitualTemplateCreated(id);
    }

    function createRitualTemplatePool(
        LibRitualComponents.RitualCost[] memory creationCosts,
        LibConstraints.Constraint[] memory creationConstraints
    ) internal returns (uint256 id) {
        HatcheryRitualStorage storage hrs = hatcheryRitualStorage();
        id = nextRitualTemplatePoolId();
        for (uint256 i = 0; i < creationConstraints.length; ++i) {
            hrs.creationConstraintsByTemplatePoolId[id].push(
                creationConstraints[i]
            );
        }

        for (uint256 i = 0; i < creationCosts.length; ++i) {
            hrs.creationCostsByTemplatePoolId[id].push(creationCosts[i]);
        }
        emit RitualTemplatePoolCreated(id);
    }

    function addRitualTemplateToPool(
        uint256 ritualTemplateId,
        uint256 ritualPoolId,
        uint256 rngWeight
    ) internal {
        require(
            ritualTemplateExists(ritualTemplateId),
            "LibHatcheryRituals: ritualTemplateId does not exist"
        );
        //require(ritualPoolExists(ritualPoolId), "LibHatcheryRituals: Pool does not exist");
        HatcheryRitualStorage storage hrs = hatcheryRitualStorage();
        hrs.ritualTemplateIdsByTemplatePoolId[ritualPoolId].push(
            ritualTemplateId
        );
        hrs.ritualTemplateWeightsByTemplatePoolId[ritualPoolId].push(rngWeight);
        hrs.ritualTemplateSumWeightByTemplatePoolId[ritualPoolId] += rngWeight;
    }

    function removeRitualTemplateFromPool(
        uint256 ritualTemplateId,
        uint256 ritualPoolId
    ) internal {
        //  TODO: Find the index of ritualTemplateId in ritualTemplateIdsByTemplatePoolId[ritualPoolId]
        //    subtract ritualTemplateWeightsByTemplatePoolId[ritualPoolId][index] from  ritualTemplateSumWeightByTemplatePoolId[ritualPoolId]
        //    delete index out of ritualTemplateIdsByTemplatePoolId[ritualPoolId]
        //    delete index out of hrs.ritualTemplateWeightsByTemplatePoolId[ritualPoolId]
        revert("Function not implemented");
    }

    function createAffix(Affix memory affix) internal returns (uint256 id) {
        id = nextAffixId();
        hatcheryRitualStorage().affixById[id] = affix;
        emit AffixCreated(id);
    }

    function createAffixBucket(
        uint256[] memory affixIds
    ) internal returns (uint256 affixBucketId) {
        HatcheryRitualStorage storage hrs = hatcheryRitualStorage();
        affixBucketId = nextHatcheryBucketId();
        for (uint256 i = 0; i < affixIds.length; i++) {
            hatcheryRitualStorage().affixIdsByAffixBucketId[affixBucketId].push(
                affixIds[i]
            );
        }
        emit AffixBucketCreated(affixBucketId, affixIds);
    }

    function addAffixesToBucket(
        uint256[] memory affixIds,
        uint256 bucketId
    ) internal {
        //This creates the bucket implicitly.
        require(affixBucketExists(bucketId), "Bucket does not exist");
        require(affixesExist(affixIds), "Some affixes do not exist");
        for (uint256 i = 0; i < affixIds.length; i++) {
            hatcheryRitualStorage().affixIdsByAffixBucketId[bucketId].push(
                affixIds[i]
            );
        }
    }

    function removeAffixFromBucket(uint256 affixId, uint256 bucketId) internal {
        require(affixBucketExists(bucketId), "Bucket does not exist");
        require(affixExists(affixId), "Affix does not exist");
        uint256[] storage affixIds = hatcheryRitualStorage()
            .affixIdsByAffixBucketId[bucketId];
        for (uint256 i = 0; i < affixIds.length; i++) {
            if (affixIds[i] == affixId) {
                affixIds[i] = affixIds[affixIds.length - 1];
                affixIds.pop();
                break;
            }
        }
    }

    function affixBucketExists(uint256 bucketId) private view returns (bool) {
        return
            hatcheryRitualStorage().affixIdsByAffixBucketId[bucketId].length >
            0;
    }

    function affixExists(uint256 affixId) private view returns (bool) {
        return
            hatcheryRitualStorage().affixById[affixId].affixType ==
            AffixType.NONE;
    }

    function affixesExist(
        uint256[] memory affixIds
    ) private view returns (bool) {
        for (uint256 i = 0; i < affixIds.length; i++) {
            if (affixExists(affixIds[i]) == false) {
                return false;
            }
        }
        return true;
    }

    function ritualPoolExists(
        uint256 ritualPoolId
    ) private view returns (bool) {
        return
            hatcheryRitualStorage()
                .ritualTemplateIdsByTemplatePoolId[ritualPoolId]
                .length > 0;
    }

    function ritualTemplateExists(
        uint256 ritualTemplateId
    ) private view returns (bool) {
        BasicRitualTemplate memory basicRitualTemplate = hatcheryRitualStorage()
            .basicRitualTemplateByRitualTemplateId[ritualTemplateId];
        return
            basicRitualTemplate.charges > 0 || basicRitualTemplate.rarity > 0;
    }

    function createRitual(uint256 ritualTemplatePoolId) internal {
        HatcheryRitualStorage storage hrs = hatcheryRitualStorage();
        require(
            ritualPoolExists(ritualTemplatePoolId),
            "LibHatcheryRituals: Pool does not exist"
        );
        checkConstraints(
            hrs.creationConstraintsByTemplatePoolId[ritualTemplatePoolId],
            msg.sender
        );
        payCosts(hrs.creationCostsByTemplatePoolId[ritualTemplatePoolId]);
        uint256 vrfRequestId = LibRNG.requestRandomness(CALLBACK_SIGNATURE);
        saveCreateRitualData(ritualTemplatePoolId, msg.sender, vrfRequestId);
        emit BeginRitualCreation(
            msg.sender,
            ritualTemplatePoolId,
            vrfRequestId
        );
    }

    function selectAndApplyAffixesSimple(
        uint256 ritualTemplateId,
        uint256 randomness
    ) internal returns (RitualTemplate memory) {
        RitualTemplate memory ritualTemplate = getRitualTemplateById(
            ritualTemplateId
        );
        uint256[] memory affixIdsToApply = selectAffixes(
            ritualTemplateId,
            randomness
        );
        return applyAffixes(ritualTemplate, affixIdsToApply);
    }

    event ExternalErrorLog(bytes message, string key, uint256 keyvalue);

    function createRitualFulfillRandomness(
        uint256 vrfRequestId,
        uint256 randomness
    ) internal {
        HatcheryRitualStorage storage hrs = hatcheryRitualStorage();
        uint256 ritualTemplatePoolId = hrs.ritualTemplatePoolIdByVRFRequestId[
            vrfRequestId
        ];
        address playerWallet = hrs.playerWalletByVRFRequestId[vrfRequestId];
        uint256 ritualTemplateId = selectRitualTemplateFromPool(
            randomness,
            ritualTemplatePoolId
        );
        (
            RitualTemplate memory ritualTemplateWithAffixesApplied,
            uint256[] memory affixIdsApplied
        ) = selectAndApplyAffixes(ritualTemplateId, randomness);
        string memory name = LibRitualNames.getRandomName(randomness);
        uint256 ritualTokenId = IRitualFacet(LibResourceLocator.ritualNFT())
            .createRitual(
                playerWallet, //to
                name, // name
                ritualTemplateWithAffixesApplied.rarity, //rarity
                ritualTemplateWithAffixesApplied.consumptionCosts, //costs
                ritualTemplateWithAffixesApplied.consumptionProducts, //products
                ritualTemplateWithAffixesApplied.consumptionConstraints, //constraints
                ritualTemplateWithAffixesApplied.charges, // charges
                ritualTemplateWithAffixesApplied.soulbound //soulbound
            );
        emit FinishRitualCreation(
            vrfRequestId,
            ritualTemplateId,
            ritualTokenId,
            affixIdsApplied,
            playerWallet
        );
    }

    function selectRitualTemplateFromPool(
        uint256 randomness,
        uint256 ritualTemplatePoolId
    ) internal view returns (uint256) {
        HatcheryRitualStorage storage hrs = hatcheryRitualStorage();
        uint256[] memory ritualTemplateIds = hrs
            .ritualTemplateIdsByTemplatePoolId[ritualTemplatePoolId];
        uint256[] memory weights = hrs.ritualTemplateWeightsByTemplatePoolId[
            ritualTemplatePoolId
        ];
        uint256 totalWeight = hrs.ritualTemplateSumWeightByTemplatePoolId[
            ritualTemplatePoolId
        ];
        uint256 target = LibRNG.expand(totalWeight, randomness, SALT_1);
        uint256 cumulativeWeight = 0;
        for (uint256 i = 0; i < ritualTemplateIds.length; i++) {
            cumulativeWeight += weights[i];
            if (target < cumulativeWeight) {
                return ritualTemplateIds[i];
            }
        }
    }

    function selectAffixFromBucket(
        uint256 randomness,
        uint256 affixBucketId,
        uint256 salt
    ) private view returns (uint256) {
        uint256[] memory affixIds = hatcheryRitualStorage()
            .affixIdsByAffixBucketId[affixBucketId];
        mapping(uint256 => Affix) storage affixById = hatcheryRitualStorage()
            .affixById;
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < affixIds.length; i++) {
            totalWeight += affixById[affixIds[i]].weight;
        }

        uint256 target = LibRNG.expand(
            totalWeight,
            randomness,
            SALT_PER_BUCKET + salt
        );
        uint256 cumulativeWeight = 0;
        for (uint256 i = 0; i < affixIds.length; i++) {
            cumulativeWeight += affixById[affixIds[i]].weight;
            if (target < cumulativeWeight) {
                return affixIds[i];
            }
        }
    }

    function selectAffixes(
        uint256 ritualTemplateId,
        uint256 randomness
    ) internal view returns (uint256[] memory affixIdsToApply) {
        uint256[] storage affixBucketIds = hatcheryRitualStorage()
            .affixBucketIdsByRitualTemplateId[ritualTemplateId];
        affixIdsToApply = new uint256[](affixBucketIds.length);
        for (uint256 i = 0; i < affixBucketIds.length; i++) {
            affixIdsToApply[i] = selectAffixFromBucket(
                randomness,
                affixBucketIds[i],
                i
            );
        }
    }

    function componentsAreEqual(
        LibRitualComponents.RitualComponent memory component1,
        LibRitualComponents.RitualComponent memory component2
    ) private pure returns (bool) {
        return
            component1.assetType == component2.assetType &&
            component1.poolId == component2.poolId &&
            component1.asset == component2.asset;
    }

    function searchIfProductIsPresent(
        RitualTemplate memory ritualTemplate,
        LibRitualComponents.RitualProduct memory product
    ) private pure returns (uint256) {
        for (
            uint256 i = 0;
            i < ritualTemplate.consumptionProducts.length;
            i++
        ) {
            if (
                componentsAreEqual(
                    ritualTemplate.consumptionProducts[i].component,
                    product.component
                )
            ) {
                return i;
            }
        }
        return type(uint256).max;
    }

    function searchIfCostIsPresent(
        RitualTemplate memory ritualTemplate,
        LibRitualComponents.RitualCost memory cost
    ) private pure returns (uint256) {
        for (uint256 i = 0; i < ritualTemplate.consumptionCosts.length; i++) {
            if (
                componentsAreEqual(
                    ritualTemplate.consumptionCosts[i].component,
                    cost.component
                )
            ) {
                return i;
            }
        }
        return type(uint256).max;
    }

    function applyAffix(
        RitualTemplate memory ritualTemplate,
        Affix memory affix
    )
        internal
        pure
        returns (
            RitualTemplate memory resultTemplate,
            bool shouldEmitWarning,
            string memory warningText
        )
    {
        shouldEmitWarning = false;
        warningText = "";
        if (affix.affixType == AffixType.CHARGES) {
            if (ritualTemplate.charges == type(uint256).max) {
                shouldEmitWarning = true;
                warningText = "Ignoring error: LibHatcheryRituals: Cannot add nor subtract from a ritual with type(uint256).max charges, leaving ritualTemplate.charges as is";
            } else if (affix.isPositive) {
                if (affix.charges == type(uint256).max) {
                    // for unlimited charges
                    ritualTemplate.charges = type(uint256).max;
                } else {
                    ritualTemplate.charges += affix.charges;
                }
            } else {
                if (affix.charges == type(uint256).max) {
                    shouldEmitWarning = true;
                    warningText = "Ignoring error: LibHatcheryRituals: Cannot have an affix were isPositive = false and charges = type(uint256).max, leaving ritualTemplate.charges as is";
                } else if (ritualTemplate.charges > affix.charges) {
                    // ritualTemplate.charges - affix.charges > 0, thus >= 1
                    ritualTemplate.charges -= affix.charges;
                } else {
                    // if ritualTemplate.charges - affix.charges == 0 or is negative, then:
                    if (affix.charges != ritualTemplate.charges) {
                        shouldEmitWarning = true;
                        warningText = "Ignoring error: LibHatcheryRituals: Cannot subtract more than the amount of charges, leaving 1 as amount of charges instead";
                    }
                    ritualTemplate.charges = 1;
                }
            }
        } else if (affix.affixType == AffixType.CONSTRAINT) {
            //Constraints are only additive
            // Then => just add the constraint to the list
            ritualTemplate.consumptionConstraints = LibArray
                .pushToConstraintMemoryArray(
                    ritualTemplate.consumptionConstraints,
                    affix.constraint
                );
        } else if (affix.affixType == AffixType.COST) {
            // Costs can be new costs or old costs.
            uint256 costIndex = searchIfCostIsPresent(
                ritualTemplate,
                affix.cost
            );
            if (affix.isPositive) {
                if (costIndex == type(uint256).max) {
                    // If the cost is not present, we add it.
                    ritualTemplate.consumptionCosts = LibArray
                        .pushToCostMemoryArray(
                            ritualTemplate.consumptionCosts,
                            affix.cost
                        );
                } else {
                    // If the cost is present, we add to that cost.
                    ritualTemplate
                        .consumptionCosts[costIndex]
                        .component
                        .amount += affix.cost.component.amount;
                }
            } else {
                if (costIndex == type(uint256).max) {
                    // If the cost is not present, we fail. Cannot subtract to a cost that is not present.
                    shouldEmitWarning = true;
                    warningText = "Ignoring error: LibHatcheryRituals: Cannot subtract to a cost that is not present";
                } else {
                    if (
                        ritualTemplate
                            .consumptionCosts[costIndex]
                            .component
                            .amount <= affix.cost.component.amount
                    ) {
                        // If the cost is present, there is at least one cost apart from this one
                        // and we subtract more than the cost, we remove cost from array
                        if (ritualTemplate.consumptionCosts.length > 1) {
                            LibArray.removeFromCostMemoryArray(
                                ritualTemplate.consumptionCosts,
                                costIndex
                            );
                        } else {
                            // If the cost is present, there is only one cost and we subtract more than the cost,
                            // we ignore the removal and emit a warning.
                            shouldEmitWarning = true;
                            warningText = "Ignoring error: LibHatcheryRituals: Cannot leave a ritual with no costs";
                        }
                    } else {
                        // If the cost is present and we subtract less than the cost, we subtract
                        ritualTemplate
                            .consumptionCosts[costIndex]
                            .component
                            .amount -= affix.cost.component.amount;
                    }
                }
            }
        } else if (affix.affixType == AffixType.PRODUCT) {
            // Product can be new product or old product.
            uint256 productIndex = searchIfProductIsPresent(
                ritualTemplate,
                affix.product
            );
            if (affix.isPositive) {
                if (productIndex == type(uint256).max) {
                    // If the product is not present, we add it.
                    ritualTemplate.consumptionProducts = LibArray
                        .pushToProductMemoryArray(
                            ritualTemplate.consumptionProducts,
                            affix.product
                        );
                } else {
                    // If the product is present, we add to that product.
                    ritualTemplate
                        .consumptionProducts[productIndex]
                        .component
                        .amount += affix.product.component.amount;
                }
            } else {
                if (productIndex == type(uint256).max) {
                    // If the product is not present, we fail. Cannot subtract to a product that is not present.
                    shouldEmitWarning = true;
                    warningText = "Ignoring error: LibHatcheryRituals: Cannot subtract to a product that is not present";
                } else {
                    if (
                        ritualTemplate
                            .consumptionProducts[productIndex]
                            .component
                            .amount <= affix.product.component.amount
                    ) {
                        // If the product is present, there is at least one product apart from this one
                        // and we subtract more than the product, we remove product from array
                        if (ritualTemplate.consumptionProducts.length > 1) {
                            LibArray.removeFromProductMemoryArray(
                                ritualTemplate.consumptionProducts,
                                productIndex
                            );
                        } else {
                            // If the product is present, there is only one product and we subtract more than the product,
                            // we ignore the removal and emit a warning.
                            shouldEmitWarning = true;
                            warningText = "Ignoring error: LibHatcheryRituals: Cannot leave a ritual with no products";
                        }
                    } else {
                        // If the product is present and we subtract less than the product, we subtract
                        ritualTemplate
                            .consumptionProducts[productIndex]
                            .component
                            .amount -= affix.product.component.amount;
                    }
                }
            }
        } else if (affix.affixType == AffixType.SOULBOUND) {
            //isPositive == true means that the ritual becomes soulbound
            //isPositive == false means that the ritual becomes not soulbound
            ritualTemplate.soulbound = affix.isPositive;
        }
        // implicitly: applyAffix(AffixType.NONE) => do nothing
        resultTemplate = ritualTemplate;
    }

    function applyAffixes(
        RitualTemplate memory ritualTemplate,
        uint256[] memory affixIdsToApply
    ) private returns (RitualTemplate memory) {
        string memory warningText = "";
        bool shouldEmitWarning = false;
        for (uint256 i = 0; i < affixIdsToApply.length; i++) {
            Affix memory affix = hatcheryRitualStorage().affixById[
                affixIdsToApply[i]
            ];
            bool _shouldEmitWarning;
            string memory _warningText;
            RitualTemplate memory _ritualTemplate;
            (_ritualTemplate, _shouldEmitWarning, _warningText) = applyAffix(
                ritualTemplate,
                affix
            );

            if (_shouldEmitWarning) {
                shouldEmitWarning = true;
                warningText = string.concat(
                    warningText,
                    " // ",
                    _warningText,
                    ", affixId:",
                    LibString.uintToString(affixIdsToApply[i])
                );
            }
        }
        if (shouldEmitWarning) {
            emit HatcheryAffixWarning(warningText);
        }
        return ritualTemplate;
    }

    function selectAndApplyAffixes(
        uint256 ritualTemplateId,
        uint256 randomness
    ) internal returns (RitualTemplate memory, uint256[] memory) {
        RitualTemplate memory ritualTemplate = getRitualTemplateById(
            ritualTemplateId
        );
        uint256[] memory affixIdsToApply = selectAffixes(
            ritualTemplateId,
            randomness
        );
        return (applyAffixes(ritualTemplate, affixIdsToApply), affixIdsToApply);
    }

    function getRitualTemplateById(
        uint256 ritualTemplateId
    ) internal view returns (RitualTemplate memory ritualTemplate) {
        HatcheryRitualStorage storage hrs = hatcheryRitualStorage();
        BasicRitualTemplate memory basicRitualTemplate = hrs
            .basicRitualTemplateByRitualTemplateId[ritualTemplateId];
        ritualTemplate = RitualTemplate({
            rarity: basicRitualTemplate.rarity,
            charges: basicRitualTemplate.charges,
            soulbound: basicRitualTemplate.soulbound,
            affixBucketIds: hrs.affixBucketIdsByRitualTemplateId[
                ritualTemplateId
            ],
            consumptionConstraints: hrs
                .consumptionConstraintsByRitualTemplateId[ritualTemplateId],
            consumptionCosts: hrs.consumptionCostsByRitualTemplateId[
                ritualTemplateId
            ],
            consumptionProducts: hrs.consumptionProductsByRitualTemplateId[
                ritualTemplateId
            ]
        });
    }

    function saveCreateRitualData(
        uint256 ritualTemplatePoolId,
        address sender,
        uint256 vrfRequestId
    ) private {
        HatcheryRitualStorage storage hrs = hatcheryRitualStorage();
        hrs.ritualTemplatePoolIdByVRFRequestId[
            vrfRequestId
        ] = ritualTemplatePoolId;
        hrs.playerWalletByVRFRequestId[vrfRequestId] = sender;
    }

    function getCreationConstraintsAndCosts(
        uint256 ritualTemplatePoolId
    )
        internal
        view
        returns (
            LibConstraints.Constraint[] memory constraints,
            LibRitualComponents.RitualCost[] memory costs
        )
    {
        HatcheryRitualStorage storage hrs = hatcheryRitualStorage();
        constraints = hrs.creationConstraintsByTemplatePoolId[
            ritualTemplatePoolId
        ];
        costs = hrs.creationCostsByTemplatePoolId[ritualTemplatePoolId];
    }

    //  Clone an Affix template into a generic instance for use in a ritual
    function instantiateAffixDefinition(
        uint256 affixId,
        uint256 weight
    ) internal view returns (Affix memory) {
        return hatcheryRitualStorage().affixById[affixId];
        // return Affix(
        //     template.affixType,
        //     template.isPositive,
        //     template.charges,
        //     template.cost,
        //     template.product,
        //     template.constraint,
        //     template.weight
        // );
        // }
    }

    function mintInnateRitualsToInnateOwnerAccount(
        address _innateOwnerAccount
    ) internal {
        /*
            Baseline template ids:
            - 1: Pyrofiend (T1 Baseline Fire Minion)
            - 2: Swamplix (T1 Baseline Slime Minion)
            - 3: Shockwisp (T1 Baseline Volt Minion)
            - 4: Sorciphant (T1 Baseline Soul Minion)
            - 5: Stargrub (T1 Baseline Nebula Minion)
            - 6: Shadow Forge Key
         */
        uint8[6] memory innateRitualTemplateIds = [1, 2, 3, 4, 5, 6];
        string[6] memory innateRitualTemplateNames = [
            "Pyrofiend Ritual",
            "Swamplix Ritual",
            "Shockwisp Ritual",
            "Sorciphant Ritual",
            "Stargrub Ritual",
            "Shadow Forge Key Ritual"
        ];

        for (uint256 i = 0; i < innateRitualTemplateIds.length; i++) {
            RitualTemplate memory ritualTemplate = getRitualTemplateById(
                innateRitualTemplateIds[i]
            );
            string memory name = innateRitualTemplateNames[i];
            IRitualFacet(LibResourceLocator.ritualNFT()).createRitual(
                _innateOwnerAccount, //to
                name, // name
                ritualTemplate.rarity, //rarity
                ritualTemplate.consumptionCosts, //costs
                ritualTemplate.consumptionProducts, //products
                ritualTemplate.consumptionConstraints, //constraints
                ritualTemplate.charges, // charges
                ritualTemplate.soulbound //soulbound
            );
        }
    }

    // function initializeAffixes() internal {

    // }
    // function initializeAffixBuckets() internal {
    //     // bucketId = nextAffixBucketId();
    //     // affixBucketIdToAffixIds
    // }
    // function initializeRitualTemplates() internal {

    // }
    // function initializeRitualPools() internal {

    // }
}
