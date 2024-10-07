// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibMinion} from "../libraries/LibMinion.sol";

/// @title MinionFacet
/// @author Facundo Vidal
contract MinionFacet {
    function getMinionMultiplierForContribution(
        uint256 poolId
    ) external view returns (uint256) {
        return LibMinion.getMinionMultiplierForContribution(poolId);
    }

    function setMinionMultiplierForContribution(
        uint256[] memory poolIds,
        uint256[] memory multipliers
    ) external {
        LibContractOwner.enforceIsContractOwner();
        LibMinion.setMinionMultiplierForContribution(poolIds, multipliers);
    }
}
