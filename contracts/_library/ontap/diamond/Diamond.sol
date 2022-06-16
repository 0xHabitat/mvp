// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondBase, DiamondBaseStorage } from '@solidstate/contracts/proxy/diamond/base/DiamondBase.sol';
import { IDiamondWritable } from '@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol';
import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';

contract Diamond is DiamondBase {
    using DiamondBaseStorage for DiamondBaseStorage.Layout;
    using OwnableStorage for OwnableStorage.Layout;

    constructor(IDiamondWritable.FacetCut[] memory cuts, address target, bytes memory data) {

        uint256 n = cuts.length;

        IDiamondWritable.FacetCut[] memory facetCuts = new IDiamondWritable.FacetCut[](n);

        // facetCuts: custom params
        for (uint256 i; i < n; i++) {
            facetCuts[i] = cuts[i];
        }

        DiamondBaseStorage.layout().diamondCut(facetCuts, target, data);
        OwnableStorage.layout().owner = msg.sender;
    }
    receive() external payable {}
}