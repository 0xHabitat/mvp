// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { SafeOwnable, OwnableStorage } from "@solidstate/contracts/access/SafeOwnable.sol";
import { IDiamondLoupe } from "@solidstate/contracts/proxy/diamond/IDiamondLoupe.sol";
import { IDiamondForwarder } from "../interfaces/IDiamondForwarder.sol";

contract DiamondForwarder is IDiamondForwarder, SafeOwnable {
    using AddressUtils for address;
    using OwnableStorage for OwnableStorage.Layout;

    constructor () {
        OwnableStorage.layout().owner = msg.sender;
    }

    function forward(address diamond, bytes memory data) payable external returns (bytes memory) {
        require(diamond.isContract(), "DiamondForwarder: diamond must be contract");
        address facet = IDiamondLoupe(diamond).facetAddress(bytes4(data));
        assembly {
            let result := delegatecall(
                gas(), 
                facet, 
                add(data, 0x20), 
                mload(data), 
                0, 
                0
            )
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}