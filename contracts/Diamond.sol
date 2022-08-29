// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondBase, DiamondBaseStorage } from '@solidstate/contracts/proxy/diamond/base/DiamondBase.sol';
import { IDiamondWritable } from '@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol';
import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';

contract Diamond is DiamondBase {
    using DiamondBaseStorage for DiamondBaseStorage.Layout;
    using OwnableStorage for OwnableStorage.Layout;

    constructor(address _owner, IDiamondWritable.FacetCut[] memory cuts, address target, bytes memory data) {
        DiamondBaseStorage.layout().diamondCut(cuts, target, data);
        OwnableStorage.layout().owner = _owner;
    }
    receive() external payable {}
}