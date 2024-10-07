// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibRNG} from "../../lib/cu-osc-common/src/libraries/LibRNG.sol";

library LibRitualNames {
    uint256 private constant SALT_1 = 239;
    uint256 private constant SALT_2 = 240;
    uint256 private constant SALT_3 = 241;
    uint256 private constant SALT_4 = 242;

    bytes32 private constant RITUAL_NAMES_STORAGE_POSITION =
        keccak256("CryptoUnicorns.HatcheryRitual.Names.Storage");

    struct RitualNameStorage {
        string[] validFirstNames; //  source
        string[] validMiddleNames; //  descriptor
        string[] validLastNames; //  noun/verb
    }

    function nameStorage()
        internal
        pure
        returns (RitualNameStorage storage ns)
    {
        bytes32 position = RITUAL_NAMES_STORAGE_POSITION;
        assembly {
            ns.slot := position
        }
    }

    function getRandomName(
        uint256 randomness
    ) internal view returns (string memory) {
        RitualNameStorage storage ns = nameStorage();
        if (LibRNG.expand(100, randomness, SALT_4) < 10) {
            //  10% chance that we will skip the middle descriptor
            return
                string.concat(
                    ns.validFirstNames[
                        LibRNG.expand(
                            ns.validFirstNames.length,
                            randomness,
                            SALT_1
                        )
                    ],
                    " ",
                    ns.validLastNames[
                        LibRNG.expand(
                            ns.validLastNames.length,
                            randomness,
                            SALT_3
                        )
                    ]
                );
        } else {
            return
                string.concat(
                    ns.validFirstNames[
                        LibRNG.expand(
                            ns.validFirstNames.length,
                            randomness,
                            SALT_1
                        )
                    ],
                    " ",
                    ns.validMiddleNames[
                        LibRNG.expand(
                            ns.validMiddleNames.length,
                            randomness,
                            SALT_2
                        )
                    ],
                    " ",
                    ns.validLastNames[
                        LibRNG.expand(
                            ns.validLastNames.length,
                            randomness,
                            SALT_3
                        )
                    ]
                );
        }
    }

    function registerFirstNames(string[] memory names) internal {
        RitualNameStorage storage ns = nameStorage();
        for (uint256 i = 0; i < names.length; ++i) {
            ns.validFirstNames.push(names[i]);
        }
    }

    function registerMiddleNames(
        uint256[] memory ids,
        string[] memory names,
        bool addToRNG
    ) internal {
        RitualNameStorage storage ns = nameStorage();
        for (uint256 i = 0; i < names.length; ++i) {
            ns.validMiddleNames.push(names[i]);
        }
    }

    function registerLastNames(
        uint256[] memory ids,
        string[] memory names,
        bool addToRNG
    ) internal {
        RitualNameStorage storage ns = nameStorage();
        for (uint256 i = 0; i < names.length; ++i) {
            ns.validLastNames.push(names[i]);
        }
    }
}
