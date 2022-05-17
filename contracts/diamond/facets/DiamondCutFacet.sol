// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondBaseStorage } from "@solidstate/contracts/proxy/diamond/DiamondBaseStorage.sol";
import { OwnableInternal } from "@solidstate/contracts/access/OwnableInternal.sol";
import { IDiamondCuttable } from "@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol";

contract DiamondCutFacet is IDiamondCuttable, OwnableInternal {
    using DiamondBaseStorage for DiamondBaseStorage.Layout;

    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external onlyOwner returns (bool) {
        DiamondBaseStorage.layout().diamondCut(facetCuts, target, data);
    }
    receive() external payable {}
}