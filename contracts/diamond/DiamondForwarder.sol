// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Proxy } from "@solidstate/contracts/proxy/Proxy.sol";
import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { IDiamondLoupe } from "@solidstate/contracts/proxy/diamond/IDiamondLoupe.sol";
import { OwnableStorage } from "@solidstate/contracts/access/OwnableStorage.sol";

import 'hardhat/console.sol';

contract DiamondForwarder is Proxy {
    using AddressUtils for address;
    using OwnableStorage for OwnableStorage.Layout;

    address public owner;
    address public diamond;

    constructor (address _diamond) {
        owner == msg.sender;
        diamond = _diamond;
    }

    function forward(address _diamond, bytes memory _data) payable external returns (bytes memory) {
        require(_diamond.isContract(), "DiamondForwarder: diamond must be contract");
        address facet = IDiamondLoupe(_diamond).facetAddress(bytes4(_data));
        assembly {
            let result := delegatecall(
                gas(), 
                facet, 
                add(_data, 0x20), 
                mload(_data), 
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

    function defaultTo(address _diamond) external {
        require(msg.sender == owner, "DiamondForwader: Sender must be thee who created the contract");
        diamond = _diamond;
    }

    function _getImplementation() internal view override returns (address) {
        return IDiamondLoupe(diamond).facetAddress(msg.sig);
    }

    receive() external payable {}
}