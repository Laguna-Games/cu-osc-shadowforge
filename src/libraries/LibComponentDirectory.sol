// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibRitualComponents} from "../../lib/cu-osc-common/src/libraries/LibRitualComponents.sol";
import {LibHatcheryRituals} from "./LibHatcheryRituals.sol";

/// @custom:storage-location erc7201:games.laguna.cryptounicorns.componentDirectory
library LibComponentDirectory {
    bytes32 private constant COMPONENT_DIRECTORY_STORAGE_POSITION =
        keccak256("games.laguna.cryptounicorns.componentDirectory");

    struct ComponentDirectoryStorage {
        mapping(uint256 => LibRitualComponents.RitualComponent) componentById;
    }

    function componentDirectoryStorage()
        internal
        pure
        returns (ComponentDirectoryStorage storage cds)
    {
        bytes32 position = COMPONENT_DIRECTORY_STORAGE_POSITION;
        // solhint-disable-next-line
        assembly {
            cds.slot := position
        }
    }
}
