// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibStructs} from "./LibStructs.sol";
import {LibFarming} from "./LibFarming.sol";
import {IERC721} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {TerminusFacet} from "../../lib/web3/contracts/terminus//TerminusFacet.sol";
import {LibValidate} from "../../lib/cu-osc-common/src/libraries/LibValidate.sol";
import {IShadowcornStatsFacet} from "../../lib/cu-osc-common/src/interfaces/IShadowcornStatsFacet.sol";
import {LibLevel} from "./LibLevel.sol";
import {LevelFullInfo} from "../entities/level/LevelFullInfo.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";

/// @title LibStaking
/// @author Shiva Shanmuganathan
/// @dev Library implementation of the staking in minion hatchery.
library LibStaking {
    event ShadowcornStaked(
        uint256 indexed tokenId,
        address indexed staker,
        bool staked,
        uint256 farmableItemId,
        uint256 stakeTimestamp
    );

    event SetShadowcornFarmingData(
        address indexed player,
        uint256 indexed tokenId,
        LibStructs.FarmableItem farmingData
    );

    event ShadowcornUnstaked(
        uint256 indexed tokenId,
        address indexed staker,
        bool staked,
        uint256 farmableItemId,
        uint256 stakedTime
    );

    event ForcedUnstakeExecuted(
        address indexed player,
        uint256 indexed tokenId
    );

    event ShadowcornHarvest(
        address indexed player,
        uint256 indexed tokenId,
        uint256 indexed poolId,
        uint256 stakingRewards
    );

    uint8 private constant SHADOWCORN_CLASS_FIRE = 1;
    uint8 private constant SHADOWCORN_CLASS_SLIME = 2;
    uint8 private constant SHADOWCORN_CLASS_VOLT = 3;
    uint8 private constant SHADOWCORN_CLASS_SOUL = 4;
    uint8 private constant SHADOWCORN_CLASS_NEBULA = 5;

    uint8 private constant SHADOWCORN_STAT_MIGHT = 1;
    uint8 private constant SHADOWCORN_STAT_WICKEDNESS = 2;
    uint8 private constant SHADOWCORN_STAT_TENACITY = 3;
    uint8 private constant SHADOWCORN_STAT_CUNNING = 4;
    uint8 private constant SHADOWCORN_STAT_ARCANA = 5;

    // Position to store the staking storage
    bytes32 private constant STAKING_STORAGE_POSITION =
        keccak256("CryptoUnicorns.Staking.Storage");

    // Staking storage struct that holds all relevant stake data
    struct LibStakingStorage {
        mapping(uint256 tokenId => LibStructs.StakeData stakeData) shadowcornStakeData;
        mapping(uint256 tokenId => LibStructs.FarmableItem farmableItemData) shadowcornFarmingData;
        mapping(address user => uint256[] stakedTokenIds) userToStakedShadowcorns;
        mapping(uint256 levelId => uint256 cumulativeBonus) hatcheryLevelStakingCumulativeBonus;
        mapping(uint256 levelId => uint256 cumulativeHuskLimit) hatcheryLevelHuskLimitCumulative;
    }

    /// @notice Sets the cumulative husk limit for a given hatchery level
    /// @param hatcheryLevel - The hatchery level
    /// @param cumulativeHuskLimit - The cumulative husk limit
    /// @dev the limit should be set times * 100: example: if the limit is meant to be 0.2, the value should be set to 20.
    function setHatcheryLevelHuskLimitCumulative(
        uint256 hatcheryLevel,
        uint256 cumulativeHuskLimit
    ) internal {
        stakingStorage().hatcheryLevelHuskLimitCumulative[
            hatcheryLevel
        ] = cumulativeHuskLimit;
    }

    /// @notice Gets the cumulative husk limit for a given hatchery level
    /// @return cumulativeHuskLimit - The cumulative husk limit
    function getHatcheryLevelHuskLimitCumulative(
        uint256 hatcheryLevel
    ) internal view returns (uint256 cumulativeHuskLimit) {
        cumulativeHuskLimit = stakingStorage().hatcheryLevelHuskLimitCumulative[
            hatcheryLevel
        ];
    }

    /// @notice Sets the cumulative staking bonus for a given hatchery level
    /// @param hatcheryLevel - The hatchery level
    /// @param cumulativeBonus - The cumulative bonus
    /// @dev the bonuses should be set times * 100: example: if the bonus is meant to be 0.2, the bonus should be set to 20.
    function setHatcheryLevelCumulativeBonus(
        uint256 hatcheryLevel,
        uint256 cumulativeBonus
    ) internal {
        stakingStorage().hatcheryLevelStakingCumulativeBonus[
            hatcheryLevel
        ] = cumulativeBonus;
    }

    /// @notice Gets the cumulative staking bonus for a given hatchery level
    /// @param hatcheryLevel - The hatchery level
    function getHatcheryLevelCumulativeBonus(
        uint256 hatcheryLevel
    ) internal view returns (uint256) {
        return
            stakingStorage().hatcheryLevelStakingCumulativeBonus[hatcheryLevel];
    }

    function resetStakedArray(address user) internal {
        stakingStorage().userToStakedShadowcorns[user] = new uint256[](0);
    }

    /// @notice Get staked shadowcorns of sender
    /// @dev Returns paginated data of player's staked shadowcorns. Max page size is 12,
    /// The `moreEntriesExist` flag is TRUE when additional pages are available past the current call.
    /// The first page is 0
    /// @return stakedShadowcorns - Array of staked shadowcorns
    /// @return moreEntriesExist - Flag to indicate if more entries exist
    function getStakedShadowcorns(
        address staker,
        uint32 _pageNumber
    )
        internal
        view
        returns (uint256[] memory stakedShadowcorns, bool moreEntriesExist)
    {
        uint256 balance = stakingStorage()
            .userToStakedShadowcorns[staker]
            .length;
        uint start = _pageNumber * 12;
        uint count = balance - start;

        if (count > 12) {
            count = 12;
            moreEntriesExist = true;
        }

        stakedShadowcorns = new uint256[](count);

        for (uint i = 0; i < count; ++i) {
            uint256 indx = start + i;

            stakedShadowcorns[i] = (
                stakingStorage().userToStakedShadowcorns[staker][indx]
            );
        }
    }

    /// Transfer a Shadowcorn into the Hatchery contract to begin yield farming.
    /// @param tokenId - The NFT to transfer
    /// @param farmableItemId - Id for the product to farm
    /// @custom:emits Transfer, ShadowcornStaked
    function stakeShadowcorn(uint256 tokenId, uint256 farmableItemId) internal {
        // check valid farmable item ID
        LibFarming.enforceValidFarmableItemId(farmableItemId);

        // check if farmable item is active
        require(
            LibFarming.farmingStorage().farmableItemData[farmableItemId].active,
            "LibStaking: Farmable item not active"
        );

        IERC721 shadowcornContract = IERC721(
            LibResourceLocator.shadowcornNFT()
        );
        // check that the Shadowcorn is owned by the sender
        address shadowcornOwner = shadowcornContract.ownerOf(tokenId);
        require(
            shadowcornContract.ownerOf(tokenId) == msg.sender,
            "LibStaking: Not owner of Shadowcorn"
        );

        // transfer the Shadowcorn to the Hatchery contract
        // replace this with the special transfer function from the Shadowcorn contract
        shadowcornContract.transferFrom(msg.sender, address(this), tokenId);

        // set the staking data for the Shadowcorn
        stakingStorage().shadowcornStakeData[tokenId] = LibStructs.StakeData({
            staker: msg.sender,
            staked: true,
            farmableItemId: farmableItemId,
            stakeTimestamp: block.timestamp
        });
        // Get shadowcorn stats

        (
            uint256 might,
            uint256 wickedness,
            uint256 tenacity,
            uint256 cunning,
            uint256 arcana
        ) = IShadowcornStatsFacet(LibResourceLocator.shadowcornNFT()).getStats(
                tokenId
            );

        // set the farming data and farming bonus for the Shadowcorn
        stakingStorage().shadowcornFarmingData[tokenId] = calculateFarmingBonus(
            tokenId,
            farmableItemId,
            shadowcornOwner,
            (might + wickedness + tenacity + cunning + arcana)
        );

        // add the Shadowcorn to the staker's list of staked Shadowcorns
        stakingStorage().userToStakedShadowcorns[msg.sender].push(tokenId);

        // get the staking data
        LibStructs.StakeData memory stakeData = stakingStorage()
            .shadowcornStakeData[tokenId];

        // emit the event
        emit ShadowcornStaked(
            tokenId,
            stakeData.staker,
            stakeData.staked,
            stakeData.farmableItemId,
            stakeData.stakeTimestamp
        );
        emit SetShadowcornFarmingData(
            stakeData.staker,
            tokenId,
            stakingStorage().shadowcornFarmingData[tokenId]
        );
    }

    //  Collect any goods that have been farmed by a Shadowcorn, and immediately
    //  re-stake the Shadowcorn back to yield farming. Progress toward incomplete
    //  items is carried over.
    //  @param tokenId - The NFT to unstake
    //  @custom:emits ShadowcornHarvest
    function harvestAndRestakeShadowcorn(uint256 tokenId) internal {
        // check that the Shadowcorn is staked
        require(
            stakingStorage().shadowcornStakeData[tokenId].staked == true,
            "LibStaking: Shadowcorn not staked."
        );

        address shadowcornOwner = stakingStorage()
            .shadowcornStakeData[tokenId]
            .staker;
        require(
            shadowcornOwner == msg.sender,
            "LibStaking: Not owner of Shadowcorn."
        );

        // get the staking data
        LibStructs.StakeData memory stakeData = stakingStorage()
            .shadowcornStakeData[tokenId];

        // get the farming data
        LibStructs.FarmableItem memory farmingData = stakingStorage()
            .shadowcornFarmingData[tokenId];

        uint256 stakingRewards = calculateStakingRewards(tokenId);

        // reset the staking data for the Shadowcorn
        stakingStorage().shadowcornStakeData[tokenId] = LibStructs.StakeData({
            staker: stakeData.staker,
            staked: true,
            farmableItemId: stakeData.farmableItemId,
            stakeTimestamp: block.timestamp
        });

        // Get shadowcorn stats

        (
            uint256 might,
            uint256 wickedness,
            uint256 tenacity,
            uint256 cunning,
            uint256 arcana
        ) = IShadowcornStatsFacet(LibResourceLocator.shadowcornNFT()).getStats(
                tokenId
            );

        // reset the farming data for the Shadowcorn
        stakingStorage().shadowcornFarmingData[tokenId] = calculateFarmingBonus(
            tokenId,
            stakeData.farmableItemId,
            shadowcornOwner,
            (might + wickedness + tenacity + cunning + arcana)
        );

        // setting terminus address
        TerminusFacet terminus = TerminusFacet(
            LibResourceLocator.shadowcornItems()
        );

        // mint terminus tokens to the staker
        terminus.mint(msg.sender, farmingData.poolId, stakingRewards, "");

        // emit the harvest event
        emit ShadowcornHarvest(
            stakeData.staker,
            tokenId,
            farmingData.poolId,
            stakingRewards
        );
    }

    function returnShadowcorn(uint256 tokenId, address user) internal {
        IERC721 shadowcornContract = IERC721(
            LibResourceLocator.shadowcornNFT()
        );
        // check that the Shadowcorn is owned by the sender
        require(
            shadowcornContract.ownerOf(tokenId) == address(this),
            "LibStaking: Hatchery not in possession of Shadowcorn."
        );

        // transfer the Shadowcorn back to the owner
        shadowcornContract.transferFrom(address(this), user, tokenId);
    }

    //  Unstake a Shadowcorn, transfer it back to the owner's wallet, and collect
    //  any goods that have been farmed. Progress toward incomplete items are lost.
    //  @param tokenId - The NFT to unstake
    //  @custom:emits Transfer, ShadowcornUnstaked, ShadowcornHarvest
    function unstakeShadowcorn(uint256 tokenId) internal {
        // check that the Shadowcorn is staked
        require(
            stakingStorage().shadowcornStakeData[tokenId].staked == true,
            "LibStaking: Shadowcorn not staked."
        );

        require(
            stakingStorage().shadowcornStakeData[tokenId].staker == msg.sender,
            "LibStaking: Not owner of Shadowcorn."
        );

        // get the staking data
        LibStructs.StakeData memory stakeData = stakingStorage()
            .shadowcornStakeData[tokenId];

        // get the farming data
        LibStructs.FarmableItem memory farmingData = stakingStorage()
            .shadowcornFarmingData[tokenId];

        uint256 stakingRewards = calculateStakingRewards(tokenId);

        resetStakingData(tokenId);

        // setting terminus address
        TerminusFacet terminus = TerminusFacet(
            LibResourceLocator.shadowcornItems()
        );

        // mint terminus tokens to the staker
        terminus.mint(msg.sender, farmingData.poolId, stakingRewards, "");

        // emit the harvest event
        emit ShadowcornHarvest(
            stakeData.staker,
            tokenId,
            farmingData.poolId,
            stakingRewards
        );

        IERC721 shadowcornContract = IERC721(
            LibResourceLocator.shadowcornNFT()
        );

        // remove tokenId element from mapping user=>staked shadowcorns
        removeStakedShadowcornFromUserList(tokenId);

        // transfer the Shadowcorn back to the owner
        shadowcornContract.transferFrom(address(this), msg.sender, tokenId);

        // emit the event
        emit ShadowcornUnstaked(
            tokenId,
            stakingStorage().shadowcornStakeData[tokenId].staker,
            false,
            stakingStorage().shadowcornStakeData[tokenId].farmableItemId,
            block.timestamp -
                stakingStorage().shadowcornStakeData[tokenId].stakeTimestamp
        );
    }

    function resetStakingData(uint256 tokenId) internal {
        // reset the staking data for the Shadowcorn
        delete stakingStorage().shadowcornStakeData[tokenId];

        // reset the farming data for the Shadowcorn
        delete stakingStorage().shadowcornFarmingData[tokenId];
    }

    //  Transfer a Shadowcorn back to the owner immediately.
    //  No yields are rewarded.
    //  @custom:emits Transfer, ShadowcornUnstaked
    function forceUnstake(uint256 tokenId) internal {
        // check if ownerOf tokenId is msg.sender
        IERC721 shadowcornContract = IERC721(
            LibResourceLocator.shadowcornNFT()
        );

        // check that the Shadowcorn is staked
        require(
            stakingStorage().shadowcornStakeData[tokenId].staked == true,
            "LibStaking: Shadowcorn not staked"
        );

        // check that the msg.sender is the owner of the Shadowcorn
        require(
            stakingStorage().shadowcornStakeData[tokenId].staker == msg.sender,
            "LibStaking: Not owner of Shadowcorn"
        );

        // get the staking data
        LibStructs.StakeData memory stakeData = stakingStorage()
            .shadowcornStakeData[tokenId];

        resetStakingData(tokenId);

        // remove tokenId element from mapping user=>staked shadowcorns
        removeStakedShadowcornFromUserList(tokenId);

        // transfer the Shadowcorn back to the owner
        shadowcornContract.transferFrom(address(this), msg.sender, tokenId);

        // emit the event
        emit ShadowcornUnstaked(
            tokenId,
            stakeData.staker,
            false,
            stakeData.farmableItemId,
            block.timestamp - stakeData.stakeTimestamp
        );

        emit ForcedUnstakeExecuted(stakeData.staker, tokenId);
    }

    function calculateFarmingBonus(
        uint256 tokenId,
        uint256 farmableItemId
    )
        internal
        view
        returns (LibStructs.FarmableItem memory shadowcornFarmingData)
    {
        // Get shadowcorn stats

        (
            uint256 might,
            uint256 wickedness,
            uint256 tenacity,
            uint256 cunning,
            uint256 arcana
        ) = IShadowcornStatsFacet(LibResourceLocator.shadowcornNFT()).getStats(
                tokenId
            );
        return
            calculateFarmingBonus(
                tokenId,
                farmableItemId,
                IERC721(LibResourceLocator.shadowcornNFT()).ownerOf(tokenId),
                (might + wickedness + tenacity + cunning + arcana)
            );
    }

    function calculateFarmingBonus(
        uint256 tokenId,
        uint256 farmableItemId,
        address shadowcornOwner,
        uint256 shadowcornTotalStats
    )
        internal
        view
        returns (LibStructs.FarmableItem memory shadowcornFarmingData)
    {
        //check is shadowcorn is staked
        LibStructs.StakeData memory stakeData = stakingStorage()
            .shadowcornStakeData[tokenId];
        if (stakeData.staked) {
            shadowcornOwner = stakeData.staker;
        } else {
            shadowcornOwner = IERC721(LibResourceLocator.shadowcornNFT())
                .ownerOf(tokenId);
        }

        // check that the Shadowcorn tokenId is valid
        LibValidate.enforceNonZeroAddress(shadowcornOwner);

        // get the farming storage
        LibFarming.LibFarmingStorage storage lfs = LibFarming.farmingStorage();
        LibStructs.FarmableItem memory farmableItem = lfs.farmableItemData[
            farmableItemId
        ];
        shadowcornFarmingData = farmableItem;

        (uint256 class, uint256 rarity, uint256 stat) = IShadowcornStatsFacet(
            LibResourceLocator.shadowcornNFT()
        ).getClassRarityAndStat(tokenId, farmableItem.stat);

        // Set the baseRate to the FarmableItem’s hourlyRate (ok if this is 0)
        uint256 baseRate = farmableItem.hourlyRate;

        // If the stat is non-zero, add 1/100th of the stat to the baseRate (will later by divided by 100 when calculating rewards)
        if (stat > 0) {
            baseRate = stat;
        }

        // If receivesHatcheryLevelBonus is true, add the cumulative level bonus (the same calculation we’re currently using)
        if (farmableItem.receivesHatcheryLevelBonus) {
            uint256 hatcheryLevel = LibLevel.getHatcheryLevelForAddress(
                shadowcornOwner
            );
            baseRate += stakingStorage().hatcheryLevelStakingCumulativeBonus[
                hatcheryLevel
            ];
        }

        uint256 multiplierRate = 10;

        // If receivesRarityBonus is true, add the rarity multiplier bonus
        if (farmableItem.receivesRarityBonus) {
            multiplierRate += getMultiplicativeRarityBonus(rarity);
        }

        // If class is non-zero, and class matches the Shadowcorn, add the class multiplier bonus
        if (class > 0) {
            multiplierRate += getMultiplicativeClassBonus(
                class,
                farmableItem.class
            );
        }

        //This value is stored times 1000, it should be divided by 1000 when used
        shadowcornFarmingData.hourlyRate = baseRate * multiplierRate;

        // Calculate cap
        if (farmableItem.cap > 0) {
            // If the FarmableItem’s cap is non-zero, use that number
            shadowcornFarmingData.cap = farmableItem.cap;
        } else {
            // If the cap is zero, calculate the yield cap
            // yieldCap = (total shadowcorn stats / 10)
            uint256 yieldCap = shadowcornTotalStats;

            // yieldCap += hatchery Level Cumulative HuskLimit Bonus[level]
            yieldCap +=
                getHatcheryLevelHuskLimitCumulative(
                    LibLevel.getHatcheryLevelForAddress(shadowcornOwner)
                ) *
                10;

            // yieldCap *= getMultiplicativeRarityBonus
            yieldCap *= (10 + getMultiplicativeRarityBonus(rarity));

            shadowcornFarmingData.cap = yieldCap / 100;
        }
    }

    function getMultiplicativeClassBonus(
        uint256 shadowcornClass,
        uint256 farmableItemClass
    ) internal pure returns (uint256) {
        if (shadowcornClass == farmableItemClass) {
            //This is meant to be 0.5
            return 5;
        }
        return 0;
    }

    function getMultiplicativeRarityBonus(
        uint256 rarity
    ) internal pure returns (uint256) {
        if (rarity == 1) {
            //This is meant to be 0.1
            return 1;
        } else if (rarity == 2) {
            //This is meant to be 1
            return 10;
        }
        //This is meant to be 4
        return 40;
    }

    function calculateStakingRewards(
        uint256 tokenId
    ) internal view returns (uint256) {
        // get the staking storage
        LibStakingStorage storage lss = stakingStorage();

        // get the staking data
        LibStructs.StakeData memory stakeData = lss.shadowcornStakeData[
            tokenId
        ];

        // get the farming data
        LibStructs.FarmableItem memory farmingData = lss.shadowcornFarmingData[
            tokenId
        ];

        // get the time since the last update
        uint256 timeSinceStaking = block.timestamp - stakeData.stakeTimestamp;

        // calculate the staking reward
        uint256 stakingReward = (timeSinceStaking * farmingData.hourlyRate) /
            3600;

        //Divide by 1000 to scale back to the original value
        stakingReward = stakingReward / 1000;

        // if the staking reward is greater than the cap, set it to the cap
        if (stakingReward > farmingData.cap) {
            stakingReward = farmingData.cap;
        }

        return stakingReward;
    }

    function stakingStorage()
        internal
        pure
        returns (LibStakingStorage storage lss)
    {
        bytes32 position = STAKING_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lss.slot := position
        }
    }

    function removeStakedShadowcornFromUserList(uint256 _tokenId) internal {
        LibStakingStorage storage lss = stakingStorage();
        uint256[] storage arr = lss.userToStakedShadowcorns[msg.sender];

        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == _tokenId) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                return;
            }
        }
        revert("LibStaking: shadowcorn not found on user list.");
    }

    function getFarmingBonusBreakdown(
        uint256 tokenId
    )
        internal
        view
        returns (
            uint256 baseRate,
            uint256 hatcheryLevelBonus,
            uint256 classBonus,
            uint256 rarityBonus
        )
    {
        // get the farming storage
        LibStructs.FarmableItem memory farmableItem = stakingStorage()
            .shadowcornFarmingData[tokenId];

        (uint256 class, uint256 rarity, uint256 stat) = IShadowcornStatsFacet(
            LibResourceLocator.shadowcornNFT()
        ).getClassRarityAndStat(tokenId, farmableItem.stat);

        baseRate = stat;
        LibStructs.StakeData memory stakeData = stakingStorage()
            .shadowcornStakeData[tokenId];
        address shadowcornOwner;
        if (stakeData.staked) {
            shadowcornOwner = stakeData.staker;
        } else {
            shadowcornOwner = IERC721(LibResourceLocator.shadowcornNFT())
                .ownerOf(tokenId);
        }
        uint256 hatcheryLevel = LibLevel.getHatcheryLevelForAddress(
            shadowcornOwner
        );
        hatcheryLevelBonus = stakingStorage()
            .hatcheryLevelStakingCumulativeBonus[hatcheryLevel];

        classBonus = getMultiplicativeClassBonus(class, farmableItem.class);
        rarityBonus = getMultiplicativeRarityBonus(rarity);
    }

    function getFarmingRateByFarmableItems(
        uint256 tokenId,
        uint256[] memory farmableItemIds
    ) internal view returns (uint256[] memory) {
        uint256 length = farmableItemIds.length;
        uint256[] memory husksPerFarmable = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            husksPerFarmable[i] = calculateFarmingBonus(
                tokenId,
                farmableItemIds[i]
            ).hourlyRate;
        }
        return husksPerFarmable;
    }

    function getFarmingHusksPerHour(
        uint256 tokenId
    )
        internal
        view
        returns (
            uint256 fireHusks,
            uint256 slimeHusks,
            uint256 voltHusks,
            uint256 soulHusks,
            uint256 nebulaHusks
        )
    {
        //This should then be divided by 1000 when used
        IERC721 shadowcornContract = IERC721(
            LibResourceLocator.shadowcornNFT()
        );
        address shadowcornOwner = shadowcornContract.ownerOf(tokenId);
        uint256 hatcheryLevel = LibLevel.getHatcheryLevelForAddress(
            shadowcornOwner
        );
        uint256 hatcheryLevelBonus = stakingStorage()
            .hatcheryLevelStakingCumulativeBonus[hatcheryLevel];
        uint256 rarityBonus = getMultiplicativeRarityBonus(
            IShadowcornStatsFacet(LibResourceLocator.shadowcornNFT()).getRarity(
                tokenId
            )
        );
        uint256 class = IShadowcornStatsFacet(
            LibResourceLocator.shadowcornNFT()
        ).getClass(tokenId);
        fireHusks = getFireHuskRate(
            tokenId,
            rarityBonus,
            hatcheryLevelBonus,
            class
        );
        slimeHusks = getSlimeHuskRate(
            tokenId,
            rarityBonus,
            hatcheryLevelBonus,
            class
        );
        voltHusks = getVoltHuskRate(
            tokenId,
            rarityBonus,
            hatcheryLevelBonus,
            class
        );
        soulHusks = getSoulHuskRate(
            tokenId,
            rarityBonus,
            hatcheryLevelBonus,
            class
        );
        nebulaHusks = getNebulaHuskRate(
            tokenId,
            rarityBonus,
            hatcheryLevelBonus,
            class
        );
    }

    function getFireHuskRate(
        uint256 tokenId,
        uint256 rarityBonus,
        uint256 hatcheryLevelBonus,
        uint256 class
    ) internal view returns (uint256) {
        uint256 might = IShadowcornStatsFacet(
            LibResourceLocator.shadowcornNFT()
        ).getMight(tokenId);
        uint256 fireClassBonus = getMultiplicativeClassBonus(class, 1);
        return
            (might + hatcheryLevelBonus) * (10 + rarityBonus + fireClassBonus);
    }

    function getSlimeHuskRate(
        uint256 tokenId,
        uint256 rarityBonus,
        uint256 hatcheryLevelBonus,
        uint256 class
    ) internal view returns (uint256) {
        uint256 wickedness = IShadowcornStatsFacet(
            LibResourceLocator.shadowcornNFT()
        ).getWickedness(tokenId);
        uint256 slimeClassBonus = getMultiplicativeClassBonus(class, 2);
        return
            (wickedness + hatcheryLevelBonus) *
            (10 + rarityBonus + slimeClassBonus);
    }

    function getVoltHuskRate(
        uint256 tokenId,
        uint256 rarityBonus,
        uint256 hatcheryLevelBonus,
        uint256 class
    ) internal view returns (uint256) {
        uint256 tenacity = IShadowcornStatsFacet(
            LibResourceLocator.shadowcornNFT()
        ).getTenacity(tokenId);
        uint256 voltClassBonus = getMultiplicativeClassBonus(class, 3);
        return
            (tenacity + hatcheryLevelBonus) *
            (10 + rarityBonus + voltClassBonus);
    }

    function getSoulHuskRate(
        uint256 tokenId,
        uint256 rarityBonus,
        uint256 hatcheryLevelBonus,
        uint256 class
    ) internal view returns (uint256) {
        uint256 cunning = IShadowcornStatsFacet(
            LibResourceLocator.shadowcornNFT()
        ).getCunning(tokenId);
        uint256 soulClassBonus = getMultiplicativeClassBonus(class, 4);
        return
            (cunning + hatcheryLevelBonus) *
            (10 + rarityBonus + soulClassBonus);
    }

    function getNebulaHuskRate(
        uint256 tokenId,
        uint256 rarityBonus,
        uint256 hatcheryLevelBonus,
        uint256 class
    ) internal view returns (uint256) {
        uint256 arcana = IShadowcornStatsFacet(
            LibResourceLocator.shadowcornNFT()
        ).getArcana(tokenId);
        uint256 nebulaClassBonus = getMultiplicativeClassBonus(class, 5);
        return
            (arcana + hatcheryLevelBonus) *
            (10 + rarityBonus + nebulaClassBonus);
    }

    function getFarmableItemByShadowcornId(
        uint256 tokenId
    ) internal view returns (LibStructs.FarmableItem memory) {
        return stakingStorage().shadowcornFarmingData[tokenId];
    }

    /// @notice Computes the time remaining until the cap is reached for a given token
    /// @param tokenId The ID of the token for which to calculate the time
    /// @return timeToReachCap The time remaining, in seconds, until the cap is reached
    function computeTimeToReachCap(
        uint256 tokenId
    ) internal view returns (uint256 timeToReachCap) {
        // get the farming data
        LibStructs.FarmableItem memory farmingData = stakingStorage()
            .shadowcornFarmingData[tokenId];

        // get the staking data
        LibStructs.StakeData memory stakeData = stakingStorage()
            .shadowcornStakeData[tokenId];

        if (stakeData.stakeTimestamp == 0) {
            return 0;
        }

        // get the time since the last update
        uint256 timeSinceStaking = block.timestamp - stakeData.stakeTimestamp;

        // cap = hourlyRate * totalTimeToReachCap
        // totalTimeToReachCap = cap / hourlyRate
        // Convert totalTimeToReachCap to seconds and hourlyRate to decimals by multiplying with 3600 and 1000 respectively.
        uint256 totalTimeToReachCap = ((farmingData.cap * 3600 * 1000) /
            farmingData.hourlyRate);

        if (timeSinceStaking > totalTimeToReachCap) {
            return 0;
        }

        timeToReachCap = totalTimeToReachCap - timeSinceStaking;

        return (timeToReachCap);
    }

    /// @notice Computes the time remaining until the next husk is created for a given token
    /// @param tokenId The ID of the token for which to calculate the time
    /// @return timeUntilNextHusk The time remaining, in seconds, until the next husk is created
    function getTimeUntilNextHusk(
        uint256 tokenId
    ) internal view returns (uint256 timeUntilNextHusk) {
        // get the farming data
        LibStructs.FarmableItem memory farmingData = stakingStorage()
            .shadowcornFarmingData[tokenId];

        // get the staking data
        LibStructs.StakeData memory stakeData = stakingStorage()
            .shadowcornStakeData[tokenId];

        // get hourly rate and time to get single husk
        uint256 hourlyRate = farmingData.hourlyRate;
        uint256 timeToGetSingleHusk = (3600 * 1000) / (hourlyRate);

        // get the time since the last update
        uint256 timeSinceStaking = block.timestamp - stakeData.stakeTimestamp;

        if (timeToGetSingleHusk >= timeSinceStaking) {
            return timeToGetSingleHusk - timeSinceStaking;
        }

        // get the time until next husk
        timeUntilNextHusk =
            timeToGetSingleHusk -
            (timeSinceStaking % timeToGetSingleHusk);

        return timeUntilNextHusk;
    }

    /// @notice Retrieves staking details including the husks created, time to reach cap, cap amount, and time until next husk
    /// @param tokenId The ID of the token for which to retrieve the details
    /// @return husksCreated The number of husks created since staking
    /// @return timeToReachCap The time remaining, in seconds, until the cap is reached
    /// @return capAmount The cap amount
    /// @return timeUntilNextHusk The time remaining, in seconds, until the next husk is created
    function getStakingDetails(
        uint256 tokenId
    )
        internal
        view
        returns (
            uint256 husksCreated,
            uint256 timeToReachCap,
            uint256 capAmount,
            uint256 timeUntilNextHusk
        )
    {
        husksCreated = calculateStakingRewards(tokenId);
        timeToReachCap = computeTimeToReachCap(tokenId);
        capAmount = stakingStorage().shadowcornFarmingData[tokenId].cap;
        timeUntilNextHusk = getTimeUntilNextHusk(tokenId);

        return (husksCreated, timeToReachCap, capAmount, timeUntilNextHusk);
    }

    /// @notice Retrieves the staking information for a specific Shadowcorn token
    /// @param tokenId The ID of the Shadowcorn token for which to retrieve the staking information
    /// @return A LibStructs.StakeData struct containing the staking details for the specified token
    function getStakingInfoByShadowcornId(
        uint256 tokenId
    ) internal view returns (LibStructs.StakeData memory) {
        return stakingStorage().shadowcornStakeData[tokenId];
    }

    function getHatcheryLevelFullInfo(
        uint256 _hatcheryLevel
    ) internal view returns (LevelFullInfo memory fullInfo) {
        fullInfo.unlockCosts = LibLevel.getHatcheryLevelUnlockCosts(
            _hatcheryLevel
        );
        fullInfo.cumulativeBonus = getHatcheryLevelCumulativeBonus(
            _hatcheryLevel
        );
        fullInfo.cumulativeHuskLimit = getHatcheryLevelHuskLimitCumulative(
            _hatcheryLevel
        );
        fullInfo.hatcheryLevel = _hatcheryLevel;
    }

    function getHatcheryLevelsFullInfo(
        uint8 page
    ) internal view returns (LevelFullInfo[5] memory levelsInfo) {
        uint256 initialLevel = page * 5 + 1;
        for (uint256 i = 0; i < 5; i++) {
            levelsInfo[i] = getHatcheryLevelFullInfo(initialLevel + i);
        }
    }
}
