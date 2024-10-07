// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IConstraintFacet} from "../../lib/cu-osc-common/src/interfaces/IConstraintFacet.sol";
import {LibConstraintOperator} from "../../lib/cu-osc-common/src/libraries/LibConstraintOperator.sol";
import {LibConstraints} from "../../lib/cu-osc-common/src/libraries/LibConstraints.sol";
import {LibLevel} from "./LibLevel.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibStaking} from "../libraries/LibStaking.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";

library LibHatcheryRitualConstraints {
    // @notice This function is used to check a constraint.
    // @param constraint The constraint to check.
    function checkConstraint(
        LibConstraints.Constraint memory constraint,
        address user
    ) internal view {
        LibConstraints.enforceValidConstraintType(constraint.constraintType);
        LibConstraints.ConstraintType constraintType = LibConstraints
            .ConstraintType(constraint.constraintType);
        if (constraintType == LibConstraints.ConstraintType.HATCHERY_LEVEL) {
            require(
                checkHatcheryLevelConstraint(
                    constraint.operator,
                    constraint.value,
                    user
                ),
                "LibHatcheryRitualConstraints: hatchery level constraint not met."
            );
        } else if (
            (constraintType >=
                LibConstraints.ConstraintType.SHADOWCORN_RARITY &&
                constraintType <=
                LibConstraints.ConstraintType.SHADOWCORN_ARCANA) ||
            constraintType == LibConstraints.ConstraintType.BALANCE_SHADOWCORN
        ) {
            require(
                checkShadowcornConstraint(constraint, user),
                "LibHatcheryRitualConstraints: shadowcorn constraint not met."
            );
        } else if (
            constraintType == LibConstraints.ConstraintType.BALANCE_UNICORN
        ) {
            require(
                checkUnicornBalanceConstraint(constraint, user),
                "LibHatcheryRitualConstraints: unicorn balance constraint not met."
            );
        }
    }

    // @notice This function is used to check if the user meets the hatchery level constraint.
    // @param operator The conditional operator that will be checked against the constraintType
    // @param value The value that will be checked with the operator against the constraintType
    function checkHatcheryLevelConstraint(
        uint256 operator,
        uint256 value,
        address user
    ) internal view returns (bool) {
        return
            LibConstraintOperator.checkOperator(
                LibLevel.getHatcheryLevelForAddress(user),
                operator,
                value
            );
    }

    // @notice This function is used to check if the user meets a shadowcorn constraint.
    // @param constraint The constraint to check.
    function checkShadowcornConstraint(
        LibConstraints.Constraint memory constraint,
        address user
    ) internal view returns (bool) {
        return
            IConstraintFacet(LibResourceLocator.shadowcornNFT())
                .checkConstraintForUserAndExtraTokens(
                    user,
                    constraint,
                    LibStaking.stakingStorage().userToStakedShadowcorns[user]
                );
    }

    // @notice This function is used to check if the user meets the unicorn balance constraint.
    // @param operator The conditional operator that will be checked against the constraintType
    // @param value The value that will be checked with the operator against the constraintType
    function checkUnicornBalanceConstraint(
        LibConstraints.Constraint memory constraint,
        address user
    ) internal view returns (bool) {
        return
            IConstraintFacet(LibResourceLocator.unicornNFT()).checkConstraint(
                user,
                constraint
            );
    }
}
