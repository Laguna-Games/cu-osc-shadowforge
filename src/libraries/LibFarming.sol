// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibStructs} from "./LibStructs.sol";
import {IERC721} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {TerminusFacet} from "../../lib/web3/contracts/terminus/TerminusFacet.sol";
import {LibConstraints} from "../../lib/cu-osc-common/src/libraries/LibConstraints.sol";
import {LibConstraintOperator} from "../../lib/cu-osc-common/src/libraries/LibConstraintOperator.sol";
import {IConstraintFacet} from "../../lib/cu-osc-common/src/interfaces/IConstraintFacet.sol";
import {LibValidate} from "../../lib/cu-osc-common/src/libraries/LibValidate.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";

/// @title LibFarming
/// @author Shiva Shanmuganathan
/// @dev Library implementation of the yield farming in minion hatchery.
/// @custom:storage-location erc7201:games.laguna.cryptounicorns.farming
library LibFarming {
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
    event FarmableItemDeactivated(
        address indexed admin,
        uint256 farmableItemId
    );
    event FarmableItemDeleted(address indexed admin, uint256 farmableItemId);

    // Position to store the farming storage
    bytes32 private constant FARMING_STORAGE_POSITION =
        keccak256("games.laguna.cryptounicorns.farming");

    // Farming storage struct that holds all relevant stake data
    struct LibFarmingStorage {
        uint256 farmableItemCount;
        mapping(uint256 farmableItemId => LibStructs.FarmableItem farmableItemData) farmableItemData;
        uint256[] huskPoolIds;
        uint256[] minionPoolIds;
        mapping(uint256 huskPoolId => uint256 index) huskPoolIdToIndex;
        mapping(uint256 minionPoolId => uint256 index) minionPoolIdToIndex;
    }

    function getFarmableItemData(
        uint256 farmableItemId
    ) internal view returns (LibStructs.FarmableItem memory) {
        LibFarmingStorage storage lfs = farmingStorage();
        return lfs.farmableItemData[farmableItemId];
    }

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
    ) internal {
        // check valid farmable item ID by checking if terminus pool exists
        require(
            poolId <=
                TerminusFacet(LibResourceLocator.shadowcornItems())
                    .totalPools(),
            "LibFarming: Terminus pool does not exist."
        );

        require(class >= 0 && class < 6, "LibFarming: Invalid class."); // We can have no class (0)
        require(stat >= 0 && stat < 6, "LibFarming: Invalid stat.");

        LibFarmingStorage storage lfs = farmingStorage();

        // increment farmable item count
        lfs.farmableItemCount++;

        // get uri from terminus
        string memory uri = TerminusFacet(LibResourceLocator.shadowcornItems())
            .uri(poolId);

        // register the new farmable item
        lfs.farmableItemData[lfs.farmableItemCount] = LibStructs.FarmableItem({
            active: false,
            poolId: poolId,
            hourlyRate: hourlyRate,
            cap: cap,
            uri: uri,
            class: class,
            stat: stat,
            receivesHatcheryLevelBonus: receivesHatcheryLevelBonus,
            receivesRarityBonus: receivesRarityBonus
        });

        // emit event
        emit FarmableItemRegistered(
            msg.sender,
            lfs.farmableItemCount,
            poolId,
            hourlyRate,
            cap,
            uri
        );
    }

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
    ) internal {
        // check valid farmable item ID
        enforceValidFarmableItemId(farmableItemId);

        // get the farming storage
        LibFarmingStorage storage lfs = farmingStorage();

        // get the farmable item
        LibStructs.FarmableItem storage fi = lfs.farmableItemData[
            farmableItemId
        ];

        // check that the farmable item is not active
        require(
            fi.active == false,
            "LibFarming: Cannot modify active farmable item."
        );

        // modify the farmable item
        lfs.farmableItemData[farmableItemId].poolId = poolId;
        lfs.farmableItemData[farmableItemId].hourlyRate = hourlyRate;
        lfs.farmableItemData[farmableItemId].cap = cap;
        lfs.farmableItemData[farmableItemId].class = class;
        lfs.farmableItemData[farmableItemId].stat = stat;
        lfs
            .farmableItemData[farmableItemId]
            .receivesHatcheryLevelBonus = receivesHatcheryLevelBonus;
        lfs
            .farmableItemData[farmableItemId]
            .receivesRarityBonus = receivesRarityBonus;

        // emit event
        emit FarmableItemModified(
            msg.sender,
            farmableItemId,
            poolId,
            hourlyRate,
            cap,
            class,
            stat
        );
    }

    /// Turn on a Farmable item for use
    function activateFarmableItem(uint256 farmableItemId) internal {
        // check valid farmable item ID
        enforceValidFarmableItemId(farmableItemId);

        LibFarmingStorage storage lfs = farmingStorage();

        LibStructs.FarmableItem storage fi = lfs.farmableItemData[
            farmableItemId
        ];
        require(
            fi.active == false,
            "LibFarming: Farmable item already active."
        );
        lfs.farmableItemData[farmableItemId].active = true;
        emit FarmableItemActivated(msg.sender, farmableItemId);
    }

    /// Turn off a Farmable item for use
    function deactivateFarmableItem(uint256 farmableItemId) internal {
        // check valid farmable item ID
        enforceValidFarmableItemId(farmableItemId);

        LibFarmingStorage storage lfs = farmingStorage();

        LibStructs.FarmableItem storage fi = lfs.farmableItemData[
            farmableItemId
        ];
        require(fi.active, "LibFarming: Farmable item already inactive.");
        lfs.farmableItemData[farmableItemId].active = false;
        emit FarmableItemDeactivated(msg.sender, farmableItemId);
    }

    /// Returns a list of Farmable items that are currently active.
    function getActiveFarmables()
        internal
        view
        returns (LibStructs.FarmableItem[] memory, uint256[] memory)
    {
        LibFarmingStorage storage lfs = farmingStorage();
        uint256 activeCount = getActiveFarmableCount();
        LibStructs.FarmableItem[]
            memory activeFarmables = new LibStructs.FarmableItem[](activeCount);
        uint256 activeIndex = 0;
        uint256[] memory farmableItemIds = new uint256[](activeCount);
        for (uint256 i = 1; i <= lfs.farmableItemCount; i++) {
            if (lfs.farmableItemData[i].active) {
                activeFarmables[activeIndex] = lfs.farmableItemData[i];
                farmableItemIds[activeIndex] = i;

                activeIndex++;
            }
        }

        return (activeFarmables, farmableItemIds);
    }

    /// Returns the number of FarmableItem objects registered
    function getFarmableItemCount() internal view returns (uint256) {
        return farmingStorage().farmableItemCount;
    }

    /// Returns the number of FarmableItem objects that are active=true
    function getActiveFarmableCount() internal view returns (uint256) {
        LibFarmingStorage storage lfs = farmingStorage();
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= lfs.farmableItemCount; i++) {
            if (lfs.farmableItemData[i].active) {
                activeCount++;
            }
        }
        return activeCount;
    }

    // check valid farmable item ID by checking it is below farmableItemCount
    function enforceValidFarmableItemId(uint256 farmableItemId) internal view {
        require(
            farmableItemId > 0 &&
                farmableItemId <= farmingStorage().farmableItemCount,
            "LibFarming: Invalid farmable item ID."
        );
    }

    /// @notice Adds a new minion pool ID.
    /// @param poolId The ID of the minion pool to add.
    function addMinionPoolId(uint256 poolId) internal {
        LibFarmingStorage storage lfs = farmingStorage();
        require(
            minionPoolExists(poolId) == false,
            "LibFarming: Minion pool already exists."
        );
        lfs.minionPoolIds.push(poolId);
        lfs.minionPoolIdToIndex[poolId] = lfs.minionPoolIds.length;
    }

    /// @notice Checks if a given minion pool ID exists.
    /// @param poolId The ID of the minion pool to check.
    /// @return True if the pool ID exists, false otherwise.
    function minionPoolExists(uint256 poolId) internal view returns (bool) {
        return farmingStorage().minionPoolIdToIndex[poolId] > 0;
    }

    /// @notice Returns the index of a given minion pool ID.
    /// @param poolId The ID of the minion pool to find.
    /// @return The index of the given minion pool ID.
    function getMinionPoolIndex(
        uint256 poolId
    ) internal view returns (uint256) {
        return farmingStorage().minionPoolIdToIndex[poolId] - 1;
    }

    /// @notice Removes a given minion pool ID.
    /// @param poolId The ID of the minion pool to remove.
    function removeMinionPoolId(uint256 poolId) internal {
        LibFarmingStorage storage lfs = farmingStorage();
        require(
            minionPoolExists(poolId),
            "LibFarming: Minion pool does not exist."
        );
        uint256 index = getMinionPoolIndex(poolId);
        lfs.minionPoolIds[index] = lfs.minionPoolIds[
            lfs.minionPoolIds.length - 1
        ];
        lfs.minionPoolIds.pop();
        lfs.minionPoolIdToIndex[poolId] = 0;
    }

    /// @notice Adds a new husk pool ID.
    /// @param poolId The ID of the husk pool to add.
    function addHuskPoolId(uint256 poolId) internal {
        LibFarmingStorage storage lfs = farmingStorage();
        require(
            huskPoolExists(poolId) == false,
            "LibFarming: Husk pool already exists."
        );
        lfs.huskPoolIds.push(poolId);
        lfs.huskPoolIdToIndex[poolId] = lfs.huskPoolIds.length;
    }

    /// @notice Checks if a given husk pool ID exists.
    /// @param poolId The ID of the husk pool to check.
    /// @return True if the pool ID exists, false otherwise.
    function huskPoolExists(uint256 poolId) internal view returns (bool) {
        return farmingStorage().huskPoolIdToIndex[poolId] > 0;
    }

    /// @notice Removes a given husk pool ID.
    /// @param poolId The ID of the husk pool to remove.
    function removeHuskPoolId(uint256 poolId) internal {
        LibFarmingStorage storage lfs = farmingStorage();
        require(
            huskPoolExists(poolId),
            "LibFarming: Husk pool does not exist."
        );
        uint256 index = getHuskPoolIndex(poolId);
        lfs.huskPoolIds[index] = lfs.huskPoolIds[lfs.huskPoolIds.length - 1];
        lfs.huskPoolIds.pop();
        lfs.huskPoolIdToIndex[poolId] = 0;
    }

    /// @notice Returns the index of a given husk pool ID.
    /// @param poolId The ID of the husk pool to find.
    /// @return The index of the given husk pool ID.
    function getHuskPoolIndex(uint256 poolId) internal view returns (uint256) {
        return farmingStorage().huskPoolIdToIndex[poolId] - 1;
    }

    /// @notice Returns the list of husk pool IDs.
    /// @return huskPoolIds An array containing all the husk pool IDs.
    function getHuskPoolIds()
        internal
        view
        returns (uint256[] memory huskPoolIds)
    {
        return farmingStorage().huskPoolIds;
    }

    /// @notice Returns the list of minion pool IDs.
    /// @return minionPoolIds An array containing all the minion pool IDs.
    function getMinionPoolIds()
        internal
        view
        returns (uint256[] memory minionPoolIds)
    {
        return farmingStorage().minionPoolIds;
    }

    /// @notice Retrieves the total supply of husks by iterating through all husk pool IDs.
    /// @return totalHusks The total supply of husks across all husk pools.
    function getTotalHusks() internal view returns (uint256 totalHusks) {
        LibFarmingStorage storage lfs = farmingStorage();
        TerminusFacet terminusFacet = TerminusFacet(
            LibResourceLocator.shadowcornItems()
        );

        for (uint256 i = 0; i < lfs.huskPoolIds.length; i++) {
            totalHusks += terminusFacet.terminusPoolSupply(lfs.huskPoolIds[i]);
        }
    }

    /// @notice Retrieves the total supply of minions by iterating through all minion pool IDs.
    /// @return totalMinions The total supply of minions across all minion pools.
    function getTotalMinions() internal view returns (uint256 totalMinions) {
        LibFarmingStorage storage lfs = farmingStorage();
        TerminusFacet terminusFacet = TerminusFacet(
            LibResourceLocator.shadowcornItems()
        );

        for (uint256 i = 0; i < lfs.minionPoolIds.length; i++) {
            totalMinions += terminusFacet.terminusPoolSupply(
                lfs.minionPoolIds[i]
            );
        }
    }

    /// @notice Enforces the validity of a Terminus pool ID.
    /// @param poolId The ID of the Terminus pool to validate.
    /// @dev Reverts if the pool ID is greater than the total number of Terminus pools.
    function enforceValidTerminusPoolId(uint256 poolId) internal view {
        require(
            poolId <=
                TerminusFacet(LibResourceLocator.shadowcornItems())
                    .totalPools(),
            "LibFarming: Terminus pool does not exist."
        );
    }

    /// @notice Returns the farming storage structure.
    function farmingStorage()
        internal
        pure
        returns (LibFarmingStorage storage lfs)
    {
        bytes32 position = FARMING_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lfs.slot := position
        }
    }
}
