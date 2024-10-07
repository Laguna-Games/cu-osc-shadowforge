// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";
import {LibEnvironment} from "../../lib/cu-osc-common/src/libraries/LibEnvironment.sol";

library LibCheck {
    function enforceValidString(string memory str) internal pure {
        require(bytes(str).length > 0, "LibCheck: String cannot be empty");
    }

    function enforceValidAddress(address addr) internal pure {
        require(
            addr != address(0),
            "LibCheck: Address cannnot be zero address"
        );
    }

    function enforceValidArray(uint256[] memory array) internal pure {
        require(array.length > 0, "LibCheck: Array cannot be empty");
    }

    function enforceValidArray(string[] memory array) internal pure {
        require(array.length > 0, "LibCheck: Array cannot be empty");
    }

    function enforceValidArray(address[] memory array) internal pure {
        require(array.length > 0, "LibCheck: Array cannot be empty");
    }

    function enforceEqualArrayLength(
        uint256[] memory array1,
        uint256[] memory array2
    ) internal pure {
        enforceValidArray(array1);
        enforceValidArray(array2);
        require(
            array1.length == array2.length,
            "LibCheck: Array must be equal length"
        );
    }

    function enforceEqualArrayLength(
        uint256[] memory array1,
        string[] memory array2
    ) internal pure {
        enforceValidArray(array1);
        enforceValidArray(array2);
        require(
            array1.length == array2.length,
            "LibCheck: Array must be equal length"
        );
    }

    function enforceEqualArrayLength(
        uint256[] memory array1,
        address[] memory array2
    ) internal pure {
        enforceValidArray(array1);
        enforceValidArray(array2);
        require(
            array1.length == array2.length,
            "LibCheck: Array must be equal length"
        );
    }

    function enforceIsOwnerOrGameServer() internal view {
        require(
            msg.sender == LibContractOwner.contractOwner() ||
                msg.sender == LibResourceLocator.gameServerOracle(),
            "LibDiamond: Must be contract owner or trusted game server"
        );
    }

    function enforceBlockDeadlineIsValid(uint256 blockDeadline) internal view {
        require(
            LibEnvironment.getBlockNumber() < blockDeadline,
            "blockDeadline is overdue"
        );
    }
}
