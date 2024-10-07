// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibRitualComponents} from "../../lib/cu-osc-common/src/libraries/LibRitualComponents.sol";
import {LibConstraints} from "../../lib/cu-osc-common/src/libraries/LibConstraints.sol";

library LibArray {
    function popFromMemoryArray(
        uint256[] memory array
    ) internal pure returns (uint256[] memory) {
        require(array.length > 0, "LibArray: Cannot pop from empty array");
        assembly {
            mstore(array, sub(mload(array), 1))
        }
        return array;
        // Some important points to remember:

        // Make sure this assembly code never runs when backerList.length == 0 (don't allow the array length to underflow)

        // Don't try to use this to increase the size of an array (by replacing sub with add)

        // Only use it on variables with a type like ...[] memory (for example, don't use it on a address[10] memory or address)

        // Disclaimer: The use of inline assembly is usually not recommended. Use it with caution and at your own risk :)
        // source: https://ethereum.stackexchange.com/questions/51891/how-to-pop-from-decrease-the-length-of-a-memory-array-in-solidity
    }

    function removeFromMemoryArray(
        uint256[] memory array,
        uint256 positionToRemove
    ) internal pure returns (uint256[] memory) {
        require(array.length > 0, "LibArray: Cannot remove from empty array");
        require(
            positionToRemove < array.length,
            "LibArray: Cannot remove from array at position greater than array length"
        );
        array[positionToRemove] = array[array.length - 1];
        assembly {
            mstore(array, sub(mload(array), 1))
        }
        return array;
    }

    function pushToMemoryArray(
        uint256[] memory array,
        uint256 element
    ) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = element;
        return newArray;
    }

    function pushToConstraintMemoryArray(
        LibConstraints.Constraint[] memory array,
        LibConstraints.Constraint memory element
    ) internal pure returns (LibConstraints.Constraint[] memory) {
        LibConstraints.Constraint[]
            memory newArray = new LibConstraints.Constraint[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = element;
        return newArray;
    }

    function removeFromConstraintMemoryArray(
        LibConstraints.Constraint[] memory array,
        uint256 positionToRemove
    ) internal pure returns (LibConstraints.Constraint[] memory) {
        require(array.length > 0, "LibArray: Cannot remove from empty array");
        require(
            positionToRemove < array.length,
            "LibArray: Cannot remove from array at position greater than array length"
        );
        array[positionToRemove] = array[array.length - 1];
        assembly {
            mstore(array, sub(mload(array), 1))
        }
        return array;
    }

    function popFromConstraintMemoryArray(
        LibConstraints.Constraint[] memory array
    ) internal pure returns (LibConstraints.Constraint[] memory) {
        require(array.length > 0, "LibArray: Cannot pop from empty array");
        assembly {
            mstore(array, sub(mload(array), 1))
        }
        return array;
    }

    function pushToProductMemoryArray(
        LibRitualComponents.RitualProduct[] memory array,
        LibRitualComponents.RitualProduct memory element
    ) internal pure returns (LibRitualComponents.RitualProduct[] memory) {
        LibRitualComponents.RitualProduct[]
            memory newArray = new LibRitualComponents.RitualProduct[](
                array.length + 1
            );
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = element;
        return newArray;
    }

    function removeFromProductMemoryArray(
        LibRitualComponents.RitualProduct[] memory array,
        uint256 positionToRemove
    ) internal pure returns (LibRitualComponents.RitualProduct[] memory) {
        require(array.length > 0, "LibArray: Cannot remove from empty array");
        require(
            positionToRemove < array.length,
            "LibArray: Cannot remove from array at position greater than array length"
        );
        array[positionToRemove] = array[array.length - 1];
        assembly {
            mstore(array, sub(mload(array), 1))
        }
        return array;
    }

    function popFromProductMemoryArray(
        LibRitualComponents.RitualProduct[] memory array
    ) internal pure returns (LibRitualComponents.RitualProduct[] memory) {
        require(array.length > 0, "LibArray: Cannot pop from empty array");
        assembly {
            mstore(array, sub(mload(array), 1))
        }
        return array;
    }

    function pushToCostMemoryArray(
        LibRitualComponents.RitualCost[] memory array,
        LibRitualComponents.RitualCost memory element
    ) internal pure returns (LibRitualComponents.RitualCost[] memory) {
        LibRitualComponents.RitualCost[]
            memory newArray = new LibRitualComponents.RitualCost[](
                array.length + 1
            );
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = element;
        return newArray;
    }

    function removeFromCostMemoryArray(
        LibRitualComponents.RitualCost[] memory array,
        uint256 positionToRemove
    ) internal pure returns (LibRitualComponents.RitualCost[] memory) {
        require(array.length > 0, "LibArray: Cannot remove from empty array");
        require(
            positionToRemove < array.length,
            "LibArray: Cannot remove from array at position greater than array length"
        );
        array[positionToRemove] = array[array.length - 1];
        assembly {
            mstore(array, sub(mload(array), 1))
        }
        return array;
    }

    function popFromCostMemoryArray(
        LibRitualComponents.RitualCost[] memory array
    ) internal pure returns (LibRitualComponents.RitualCost[] memory) {
        require(array.length > 0, "LibArray: Cannot pop from empty array");
        assembly {
            mstore(array, sub(mload(array), 1))
        }
        return array;
    }
}
