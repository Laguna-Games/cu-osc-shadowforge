// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

struct Component {
    address asset; //address of the asset
    uint256 poolId; //poolId is for ERC1155 assets, doesn't need to be assigned for non 1155
    uint128 amount;
    uint128 assetType; //20 = ERC20, 721 = ERC721, 1155 = ERC1155
}
