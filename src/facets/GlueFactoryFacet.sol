// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibGlueFactory} from "../libraries/LibGlueFactory.sol";
import {LibGasReturner} from "../../lib/cu-osc-common/src/libraries/LibGasReturner.sol";

contract GlueFactoryFacet {
    function batchSacrificeUnicorns(uint256[] memory tokenIds) external {
        uint256 availableGas = gasleft();
        LibGlueFactory.batchSacrificeUnicorns(tokenIds);
        LibGasReturner.returnGasToUser(
            "batchSacrificeUnicorns",
            (availableGas - gasleft()),
            payable(msg.sender)
        );
    }

    function setUnicornSoulsPoolId(uint256 poolId) external {
        LibContractOwner.enforceIsContractOwner();
        LibGlueFactory.setUnicornSoulsPoolId(poolId);
    }

    function getUnicornSoulsPoolId() external view returns (uint256 poolId) {
        return LibGlueFactory.getUnicornSoulsPoolId();
    }

    function setMaxBatchSacrificeUnicornsAmount(
        uint256 maxBatchAmount
    ) external {
        LibContractOwner.enforceIsContractOwner();
        LibGlueFactory.setMaxBatchSacrificeUnicornsAmount(maxBatchAmount);
    }

    function getMaxBatchSacrificeUnicornsAmount()
        external
        view
        returns (uint256 maxBatchAmount)
    {
        return LibGlueFactory.getMaxBatchSacrificeUnicornsAmount();
    }
}
