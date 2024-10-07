// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibUNIMExtractor} from "../libraries/LibUNIMExtractor.sol";

/*
    @notice This facet allows the owner to extract the UNIM tokens from the contract.
 */
contract UNIMExtractorFacet {
    function extractUNIMAmount(uint256 amount) external {
        LibContractOwner.enforceIsContractOwner();
        LibUNIMExtractor.extractUNIMAmount(amount);
    }
}
