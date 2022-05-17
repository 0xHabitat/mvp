// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondBase, DiamondBaseStorage, IDiamondCuttable } from "@solidstate/contracts/proxy/diamond/DiamondBase.sol";
import { OwnableStorage } from "@solidstate/contracts/access/OwnableStorage.sol";

contract Diamond is DiamondBase {
    using DiamondBaseStorage for DiamondBaseStorage.Layout;

    constructor(IDiamondCuttable.FacetCut[] memory _cuts) {

        DiamondBaseStorage.layout().diamondCut(_cuts, address(0), "");
        OwnableStorage.layout().owner = msg.sender;
    }
}