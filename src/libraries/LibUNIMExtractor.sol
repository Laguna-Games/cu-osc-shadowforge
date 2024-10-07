// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {IERC20} from "../../lib/cu-osc-diamond-template/src/interfaces/IERC20.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";

library LibUNIMExtractor {
    function extractUNIMAmount(uint256 amount) internal {
        LibContractOwner.enforceIsContractOwner();
        IERC20(LibResourceLocator.unimToken()).transferFrom(
            address(this),
            msg.sender,
            amount
        );
    }
}
