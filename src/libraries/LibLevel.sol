// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20Burnable} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC721} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {ERC721Burnable} from "../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";
import {LevelUnlockCost} from "../entities/level/LevelUnlockCost.sol";
import {LibConstraintOperator} from "../../lib/cu-osc-common/src/libraries/LibConstraintOperator.sol";
import {LevelUpgradeBonus} from "../entities/level/LevelUpgradeBonus.sol";
import {LevelUpgradeBonusType} from "../entities/level/LevelUpgradeBonusType.sol";
import {LevelUpgradeBonusFrequency} from "../entities/level/LevelUpgradeBonusFrequency.sol";
import {LibRitualData} from "../../lib/cu-osc-common/src/libraries/LibRitualData.sol";
import {LevelUnlockCostTokenTransferType} from "../entities/level/LevelUnlockCostTokenTransferType.sol";
import {Component} from "../entities/common/Component.sol";
import {TerminusFacet} from "../../lib/web3/contracts/terminus/TerminusFacet.sol";
import {ERC1155, IERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {LibValidate} from "../../lib/cu-osc-common/src/libraries/LibValidate.sol";
import {LibRitualValidate} from "../../lib/cu-osc-common/src/libraries/LibRitualValidate.sol";
import {LibToken} from "../../lib/cu-osc-common/src/libraries/LibToken.sol";
import {IUNIMControllerFacet} from "../../lib/cu-osc-common/src/interfaces/IUNIMControllerFacet.sol";
import {IDarkMarksControllerFacet} from "../../lib/cu-osc-common/src/interfaces/IDarkMarksControllerFacet.sol";

/// @notice LibLevel
/// @author Facundo Vidal
/// @dev Implementation of Minion Hatchery leveling
library LibLevel {
    event HatcheryLevelUnlocked(
        address indexed player,
        uint256 oldLevel,
        uint256 newLevel
    );

    uint256 private constant HATCHERY_LEVEL_MIN = 1;

    bytes32 private constant HATCHERY_LEVEL_STORAGE_POSITION =
        keccak256("CryptoUnicorns.HatcheryLevel.Storage");

    /// @dev Do not modify the ordering of this struct once it has been deployed.
    /// @dev If you need to add new fields, add them to the end.
    struct LibLevelStorage {
        // Maps each user to their current level. If the user is level 1, the user might not be in this map.
        mapping(address => uint256) userToHatcheryLevel;
        // The maximum level that the hatchery can reach.
        uint256 hatcheryLevelCap;
        // Unlocking costs for each level
        mapping(uint256 => LevelUnlockCost[]) hatcheryLevelToUnlockCosts;
        // **DEPRECATED: DONT DELETE THIS, KEEP STORAGE ORDER!** Available farm slots and bonuses for each level
        mapping(uint256 => uint256) hatcheryLevelToUpgradeFarmSlots;
        // **DEPRECATED: DONT DELETE THIS, KEEP STORAGE ORDER!** Bonuses for each level
        mapping(uint256 => LevelUpgradeBonus[]) hatcheryLevelToUpgradeBonuses;
        // **DEPRECATED: DONT DELETE THIS, KEEP STORAGE ORDER!** Available rituals for each level
        mapping(uint256 => LibRitualData.BasicRitual[]) hatcheryLevelToUpgradeRituals;
    }

    function levelStorage()
        internal
        pure
        returns (LibLevelStorage storage lrs)
    {
        bytes32 position = HATCHERY_LEVEL_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lrs.slot := position
        }
    }

    /// @notice Set the unlocking costs for an specific hatchery level
    /// @notice This function will be used to set the unlocking costs for each level.
    /// @dev When setting the costs for an specific level, the previous costs will be deleted
    /// @dev There are multiple parallel arrays instead of a single array to prevent big nested structs array.
    /// @param _hatcheryLevel The level that will be unlocked
    /// @param _transferTypes The type of transfer that will be used for the cost (BURN, TRANSFER)
    /// @param _amounts The amount of tokens that will be used for the cost
    /// @param _assetTypes The type of asset that will be used for the cost (ERC20, ERC721, ERC1155)
    /// @param _assets The address of the asset that will be used for the cost
    /// @param _poolIds The pool id of the asset that will be used for the cost
    function setHatcheryLevelUnlockCosts(
        uint256 _hatcheryLevel,
        uint256[] memory _transferTypes,
        uint128[] memory _amounts,
        uint128[] memory _assetTypes,
        address[] memory _assets,
        uint256[] memory _poolIds
    ) internal {
        // Enforce that all the parameter array lengths are the same
        require(
            _amounts.length == _assetTypes.length &&
                _assetTypes.length == _assets.length &&
                _assets.length == _poolIds.length &&
                _poolIds.length == _transferTypes.length,
            "LibLevel: parameter array lengths must be the same."
        );

        // Clear old costs for level
        delete levelStorage().hatcheryLevelToUnlockCosts[_hatcheryLevel];

        for (uint256 i = 0; i < _amounts.length; i++) {
            enforceValidTransferType(_transferTypes[i]);
            enforceValidAssetType(_assetTypes[i]);
            addHatcheryLevelUnlockCost(
                _hatcheryLevel,
                LevelUnlockCostTokenTransferType(_transferTypes[i]),
                _amounts[i],
                _assetTypes[i],
                _assets[i],
                _poolIds[i]
            );
        }
    }

    /// @notice Enforce valid asset type
    /// @notice This function will revert if the asset type is not valid
    /// @param _assetType The asset type
    function enforceValidAssetType(uint256 _assetType) private pure {
        require(
            _assetType == LibToken.TYPE_ERC20 ||
                _assetType == LibToken.TYPE_ERC721 ||
                _assetType == LibToken.TYPE_ERC1155,
            "LibComponents: Invalid asset type."
        );
    }

    ///  @notice Unlock next hatchery level
    ///  @dev This function is called when a user wants to unlock the next hatchery level
    ///  @dev This function will revert if the user has reached the level cap
    ///  @dev This function will revert if the user has not unlocked the previous level
    function unlockNextHatcheryLevel() internal {
        // Get the current level
        uint256 currentLevel = getHatcheryLevelForAddress(msg.sender);

        // Get the next level
        uint256 nextLevel = currentLevel + 1;

        // Get the level cap
        uint256 levelCap = getHatcheryLevelCap();

        // Check if the user has reached the level cap
        require(
            currentLevel < levelCap,
            "LibLevel: User has reached the level cap"
        );

        LibLevelStorage storage llStorage = levelStorage();

        // Get new level costs
        LevelUnlockCost[] memory newLevelCosts = llStorage
            .hatcheryLevelToUnlockCosts[nextLevel];

        for (uint256 i = 0; i < newLevelCosts.length; i++) {
            // Get the cost
            LevelUnlockCost memory newLevelCost = newLevelCosts[i];

            if (newLevelCost.component.assetType == LibToken.TYPE_ERC20) {
                consumeERC20Cost(
                    newLevelCost.component.amount,
                    newLevelCost.component.asset,
                    newLevelCost.transferType
                );
            } else if (
                newLevelCost.component.assetType == LibToken.TYPE_ERC721
            ) {
                // TODO: implement ERC721 usage and adapt Component structure to support it.
                revert("LibLevel: ERC721 for costs was not implemented yet");
            } else if (
                newLevelCost.component.assetType == LibToken.TYPE_ERC1155
            ) {
                consumeERC1155Cost(
                    newLevelCost.component.amount,
                    newLevelCost.component.asset,
                    newLevelCost.transferType,
                    newLevelCost.component.poolId
                );
            }
        }

        // Unlock the next level
        llStorage.userToHatcheryLevel[msg.sender] = nextLevel;

        emit HatcheryLevelUnlocked(msg.sender, currentLevel, nextLevel);
    }

    /// @notice Consume ERC20 cost for hatchery leveling
    /// @notice This function will consume the ERC20 cost for hatchery leveling
    /// @dev This function will revert if the transfer type is invalid
    /// @param _amount The amount of ERC20 tokens to consume
    /// @param _asset The address of the ERC20 token
    /// @param _transferType The transfer type (BURN, TRANSFER)
    function consumeERC20Cost(
        uint256 _amount,
        address _asset,
        LevelUnlockCostTokenTransferType _transferType
    ) internal {
        if (_transferType == LevelUnlockCostTokenTransferType.BURN) {
            // Burn the tokens
            if (_asset == LibResourceLocator.unimToken()) {
                IUNIMControllerFacet(LibResourceLocator.gameBank())
                    .burnUNIMFrom(msg.sender, _amount);
            } else if (_asset == LibResourceLocator.darkMarkToken()) {
                IDarkMarksControllerFacet(LibResourceLocator.gameBank())
                    .burnDarkMarksFrom(msg.sender, _amount);
            } else {
                ERC20Burnable(_asset).burnFrom(msg.sender, _amount);
            }
            return;
        } else if (_transferType == LevelUnlockCostTokenTransferType.TRANSFER) {
            // Transfer the tokens to the game bank
            IERC20(_asset).transferFrom(
                msg.sender,
                LibResourceLocator.gameBank(),
                _amount
            );
            return;
        }

        revert("LibLevel: Invalid transfer type");
    }

    /// @notice Consume ERC1155 cost for hatchery leveling
    /// @notice This function will consume the ERC1155 or Terminus token cost for hatchery leveling
    /// @dev This function will revert if the transfer type is invalid
    /// @param _amount The amount of ERC1155/Terminus tokens to consume
    /// @param _asset The address of the ERC1155/Terminus token
    /// @param _transferType The transfer type (Only BURN is supported)
    /// @param _poolId The pool id
    function consumeERC1155Cost(
        uint256 _amount,
        address _asset,
        LevelUnlockCostTokenTransferType _transferType,
        uint256 _poolId
    ) internal {
        if (_transferType == LevelUnlockCostTokenTransferType.BURN) {
            // Burn the tokens
            TerminusFacet(_asset).burn(msg.sender, _poolId, _amount);
            return;
        }

        revert("LibLevel: Invalid transfer type");
    }

    /// @notice Get the costs to unlock an specific hatchery level
    /// @param _hatcheryLevel The level
    /// @return Array of costs with token type and quantity
    function getHatcheryLevelUnlockCosts(
        uint256 _hatcheryLevel
    ) internal view returns (LevelUnlockCost[] memory) {
        return levelStorage().hatcheryLevelToUnlockCosts[_hatcheryLevel];
    }

    /// @notice Add a cost for a hatchery level
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
        LevelUnlockCostTokenTransferType _transferType,
        uint128 _amount,
        uint128 _assetType,
        address _asset,
        uint256 _poolId
    ) internal {
        enforceValidAssetType(_assetType);

        LibValidate.enforceNonZeroAddress(_asset);

        if (_assetType == LibToken.TYPE_ERC1155) {
            // Require transferType = BURN since we are not supporting transfer for ERC1155/Terminus tokens.
            require(
                _transferType == LevelUnlockCostTokenTransferType.BURN,
                "LibLevel: must use transfer type BURN for ERC1155 or Terminus assets."
            );

            require(
                _poolId > 0,
                "LibLevel: must assign a pool id to a level cost with asset type ERC1155."
            );
        }

        // Push unlock cost to level
        levelStorage().hatcheryLevelToUnlockCosts[_hatcheryLevel].push(
            LevelUnlockCost({
                component: Component({
                    amount: _amount,
                    assetType: _assetType,
                    asset: _asset,
                    poolId: _poolId
                }),
                transferType: _transferType
            })
        );
    }

    /// @notice Get the hatchery level cap
    /// @dev This function will return the minimum level if the level cap is 0
    /// @return The level cap
    function getHatcheryLevelCap() internal view returns (uint256) {
        // Get the level cap
        uint256 levelCap = levelStorage().hatcheryLevelCap;

        // If the level cap is 0, return the minimum level cap
        return (levelCap == 0) ? HATCHERY_LEVEL_MIN : levelCap;
    }

    /// @notice Set the hatchery level cap
    /// @dev This function will revert if the level cap is 0
    /// @param _hatcheryLevelCap The level cap
    function setHatcheryLevelCap(uint256 _hatcheryLevelCap) internal {
        require(
            _hatcheryLevelCap > HATCHERY_LEVEL_MIN,
            "LibLevel: Level cap must be greater than the minimum level"
        );

        levelStorage().hatcheryLevelCap = _hatcheryLevelCap;
    }

    /// @notice Get the hatchery level for an address
    /// @param _user The address of the user
    /// @dev If the user has not been initialized, it returns 1.
    /// @return The current level of the user
    function getHatcheryLevelForAddress(
        address _user
    ) internal view returns (uint256) {
        uint256 level = levelStorage().userToHatcheryLevel[_user];

        // If the user has not been initialized, it has level 1
        return (level == 0) ? 1 : level;
    }

    /// @notice Enforces valid level
    /// @dev This function will revert if the level is not valid
    /// @param _hatcheryLevel The level to validate
    function enforceValidLevel(uint256 _hatcheryLevel) internal view {
        require(
            _hatcheryLevel >= HATCHERY_LEVEL_MIN &&
                _hatcheryLevel <= getHatcheryLevelCap(),
            "LibLevel: Level must be greater than or equal to the minimum level"
        );
    }

    /// @notice Enforces valid transfer type for token
    /// @dev This function will revert if the transfer type is not valid
    /// @param _transferType The transfer type to validate
    function enforceValidTransferType(uint256 _transferType) internal pure {
        require(
            _transferType == uint(LevelUnlockCostTokenTransferType.BURN) ||
                _transferType ==
                uint(LevelUnlockCostTokenTransferType.TRANSFER),
            "LibLevel: Invalid transfer type"
        );
    }

    /// @notice Resets hatchery level
    /// @dev This function should only be called on local or testnet for debugging purposes
    /// @param user The address of the user
    function resetHatcheryLevel(address user) internal {
        levelStorage().userToHatcheryLevel[user] = 1;
    }
}
