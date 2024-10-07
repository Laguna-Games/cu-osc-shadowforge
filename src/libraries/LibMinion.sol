// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// @custom:storage-location erc7201:games.laguna.ShadowForge.LibMinion
library LibMinion {
    // Position to store the minion storage
    bytes32 constant MINION_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256('games.laguna.ShadowForge.LibMinion')) - 1)) & ~bytes32(uint256(0xff));

    struct LibMinionStorage {
        mapping(uint256 poolId => uint256 multiplier) minionMultiplierForContribution;
    }

    function minionStorage() internal pure returns (LibMinionStorage storage lms) {
        bytes32 position = MINION_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lms.slot := position
        }
    }

    function getMinionMultiplierForContribution(uint256 poolId) internal view returns (uint256) {
        uint256 multiplier = minionStorage().minionMultiplierForContribution[poolId];

        if (multiplier == 0) {
            multiplier = 1;
        }

        return multiplier;
    }

    function setMinionMultiplierForContribution(uint256[] memory poolIds, uint256[] memory multipliers) internal {
        require(poolIds.length == multipliers.length, 'LibMinion: Invalid input lengths');

        for (uint256 i = 0; i < poolIds.length; i++) {
            minionStorage().minionMultiplierForContribution[poolIds[i]] = multipliers[i];
        }
    }
}
