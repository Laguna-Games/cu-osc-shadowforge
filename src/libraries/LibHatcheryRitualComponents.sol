// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {IERC20} from "../../lib/cu-osc-diamond-template/src/interfaces/IERC20.sol";
import {ERC20Burnable} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {LibToken} from "../../lib/cu-osc-common/src/libraries/LibToken.sol";
import {LibRitualData} from "../../lib/cu-osc-common/src/libraries/LibRitualData.sol";
import {TerminusFacet} from "../../lib/web3/contracts/terminus//TerminusFacet.sol";
import {LibRitualComponents} from "../../lib/cu-osc-common/src/libraries/LibRitualComponents.sol";
import {LibFarming} from "./LibFarming.sol";
import {LibRewards} from "./LibRewards.sol";
import {IUNIMControllerFacet} from "../../lib/cu-osc-common/src/interfaces/IUNIMControllerFacet.sol";
import {IDarkMarksControllerFacet} from "../../lib/cu-osc-common/src/interfaces/IDarkMarksControllerFacet.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";
import {LibMinion} from "./LibMinion.sol";

library LibHatcheryRitualComponents {
    // @notice This function makes the player pay a RitualCost.
    // @param cost The cost to be paid.
    function payCost(LibRitualComponents.RitualCost memory cost) internal {
        LibRitualComponents.RitualCostTransferType transferType = LibRitualComponents
                .RitualCostTransferType(cost.transferType);
        if (cost.component.assetType == LibToken.TYPE_ERC20) {
            if (
                transferType == LibRitualComponents.RitualCostTransferType.BURN
            ) {
                if (cost.component.asset == LibResourceLocator.unimToken()) {
                    IUNIMControllerFacet(LibResourceLocator.gameBank())
                        .burnUNIMFrom(msg.sender, cost.component.amount);
                } else if (
                    cost.component.asset == LibResourceLocator.darkMarkToken()
                ) {
                    IDarkMarksControllerFacet(LibResourceLocator.gameBank())
                        .burnDarkMarksFrom(msg.sender, cost.component.amount);
                } else {
                    ERC20Burnable(cost.component.asset).burnFrom(
                        msg.sender,
                        cost.component.amount
                    );
                }
            } else if (
                transferType ==
                LibRitualComponents.RitualCostTransferType.TRANSFER
            ) {
                if (cost.component.asset == LibResourceLocator.unimToken()) {
                    //HOTFIX for broken data in prod.
                    IUNIMControllerFacet(LibResourceLocator.gameBank())
                        .burnUNIMFrom(msg.sender, cost.component.amount);
                } else {
                    IERC20(cost.component.asset).transferFrom(
                        msg.sender,
                        LibResourceLocator.gameBank(),
                        cost.component.amount
                    );
                }
            }
        } else if (cost.component.assetType == LibToken.TYPE_ERC1155) {
            if (
                transferType == LibRitualComponents.RitualCostTransferType.BURN
            ) {
                TerminusFacet(cost.component.asset).burn(
                    msg.sender,
                    cost.component.poolId,
                    cost.component.amount
                );
            } else if (
                transferType ==
                LibRitualComponents.RitualCostTransferType.TRANSFER
            ) {
                revert(
                    "LibHatcheryRitualComponents: ERC1155s should not be transferred as costs."
                );
            }
        } else {
            revert("LibHatcheryRitualComponents: Invalid cost asset type.");
        }
    }

    // @notice This function makes the player receive a RitualProduct.
    // @param product The product to be received.
    function mintProduct(
        LibRitualComponents.RitualProduct memory product
    ) internal {
        LibRitualComponents.RitualProductTransferType transferType = LibRitualComponents
                .RitualProductTransferType(product.transferType);
        if (product.component.assetType == LibToken.TYPE_ERC20) {
            if (
                transferType ==
                LibRitualComponents.RitualProductTransferType.TRANSFER
            ) {
                IERC20(product.component.asset).transferFrom(
                    LibResourceLocator.gameBank(),
                    msg.sender,
                    product.component.amount
                );
            } else if (
                transferType ==
                LibRitualComponents.RitualProductTransferType.MINT
            ) {
                revert(
                    "LibHatcheryRitualComponents: ERC20 should not be minted as products."
                );
            }
        } else if (product.component.assetType == LibToken.TYPE_ERC1155) {
            if (
                transferType ==
                LibRitualComponents.RitualProductTransferType.MINT
            ) {
                TerminusFacet(product.component.asset).mint(
                    msg.sender,
                    product.component.poolId,
                    product.component.amount,
                    ""
                );
                addTokenToQueueIfMinion(
                    product.component.poolId,
                    product.component.amount,
                    msg.sender
                );
            } else if (
                transferType ==
                LibRitualComponents.RitualProductTransferType.TRANSFER
            ) {
                revert(
                    "LibHatcheryRitualComponents: ERC1155s should not be transferred as products."
                );
            }
        } else {
            revert("LibHatcheryRitualComponents: Invalid product asset type.");
        }
    }

    function addTokenToQueueIfMinion(
        uint256 poolId,
        uint256 quantity,
        address user
    ) internal {
        if (LibFarming.minionPoolExists(poolId)) {
            quantity =
                quantity *
                LibMinion.getMinionMultiplierForContribution(poolId);
            LibRewards.addToQueue(quantity, user);
        }
    }
}
