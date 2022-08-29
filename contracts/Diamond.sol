// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondBase, DiamondBaseStorage } from '@solidstate/contracts/proxy/diamond/base/DiamondBase.sol';
import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';

import { IDiamondWritable } from '@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol';
import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';

contract Diamond is DiamondBase {
    using DiamondBaseStorage for DiamondBaseStorage.Layout;
    using OwnableStorage for OwnableStorage.Layout;

    constructor(
        address _owner, 
        address _diamondCutFacet, 
        address _diamondLoupeFacet 
    /* IDiamondWritable.FacetCut[] memory cuts, address target, bytes memory data */
    ) payable {
/*         DiamondBaseStorage.layout().diamondCut(cuts, target, data); */
        OwnableStorage.layout().owner = _owner;

        IDiamondWritable.FacetCut[] memory cut = new IDiamondWritable.FacetCut[](2);

        bytes4[] memory functionSelectors1 = new bytes4[](1);
        functionSelectors1[0] = IDiamondWritable.diamondCut.selector;
        cut[0] = IDiamondWritable.FacetCut({
            target: _diamondCutFacet, 
            action: IDiamondWritable.FacetCutAction.ADD, 
            selectors: functionSelectors1
        });

        // cut diamondLoupe
        bytes4[] memory functionSelectors2 = new bytes4[](4);
        functionSelectors2[0] = IDiamondReadable.facets.selector;
        functionSelectors2[1] = IDiamondReadable.facetFunctionSelectors.selector;
        functionSelectors2[2] = IDiamondReadable.facetAddresses.selector;
        functionSelectors2[3] = IDiamondReadable.facetAddress.selector;
        cut[1] = IDiamondWritable.FacetCut({
            target: _diamondLoupeFacet, 
            action: IDiamondWritable.FacetCutAction.ADD, 
            selectors: functionSelectors2
        });

        DiamondBaseStorage.layout().diamondCut(cut, address(0), '');
    }
    receive() external payable {}
}