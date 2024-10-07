// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {TerminusFacet} from "../../lib/web3/contracts/terminus/TerminusFacet.sol";
import {IUnicornBurn} from "../../lib/cu-osc-common/src/interfaces/IUnicornBurn.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";

/// @custom:storage-location erc7201:games.laguna.cryptounicorns.glueFactory
library LibGlueFactory {
    event BatchSacrificeUnicorns(uint256[] tokenIds, address user);

    // Position to store the Glue Factory storage
    bytes32 private constant GLUE_FACTORY_STORAGE_POSITION =
        keccak256("games.laguna.cryptounicorns.glueFactory");

    // Glue Factory storage struct that holds all relevant stake data
    // DO NOT REORDER THIS VARIABLES!!
    struct LibGlueFactoryStorage {
        uint256 maxBatchSacrificeUnicornsAmount;
        uint256 unicornSoulsPoolId;
    }

    /// @notice Returns the glue factory storage structure.
    function glueFactoryStorage()
        internal
        pure
        returns (LibGlueFactoryStorage storage lgfs)
    {
        bytes32 position = GLUE_FACTORY_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lgfs.slot := position
        }
    }

    function setUnicornSoulsPoolId(uint256 poolId) internal {
        glueFactoryStorage().unicornSoulsPoolId = poolId;
    }

    function getUnicornSoulsPoolId() internal view returns (uint256 poolId) {
        return glueFactoryStorage().unicornSoulsPoolId;
    }

    function setMaxBatchSacrificeUnicornsAmount(
        uint256 maxBatchAmount
    ) internal {
        glueFactoryStorage().maxBatchSacrificeUnicornsAmount = maxBatchAmount;
    }

    function getMaxBatchSacrificeUnicornsAmount()
        internal
        view
        returns (uint256 maxBatchAmount)
    {
        return glueFactoryStorage().maxBatchSacrificeUnicornsAmount;
    }

    function batchSacrificeUnicorns(uint256[] memory tokenIds) internal {
        address user = msg.sender;
        require(
            tokenIds.length <= getMaxBatchSacrificeUnicornsAmount(),
            "LibGlueFactory: batch sacrifice amount exceeds max amount"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIds[i] != 0,
                "LibGlueFactory: token id does not exist"
            );
        }

        IUnicornBurn(LibResourceLocator.unicornNFT()).batchSacrificeUnicorns(
            tokenIds,
            user
        );

        TerminusFacet(LibResourceLocator.shadowcornItems()).mint(
            user,
            getUnicornSoulsPoolId(),
            tokenIds.length,
            ""
        );

        emit BatchSacrificeUnicorns(tokenIds, user);
    }
}
