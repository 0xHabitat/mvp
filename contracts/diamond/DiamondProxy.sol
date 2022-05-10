// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Proxy } from "@solidstate/contracts/proxy/Proxy.sol";
import { OwnableStorage } from "@solidstate/contracts/access/OwnableStorage.sol";
import { IDiamondLoupe } from "@solidstate/contracts/proxy/diamond/IDiamondLoupe.sol";

import "hardhat/console.sol";

contract DiamondProxy is Proxy {
    address private diamond;

    constructor(address _diamond) {
        diamond = _diamond;
        OwnableStorage.layout().owner = msg.sender;
    }

    function _getImplementation() internal view override returns (address) {
        return IDiamondLoupe(diamond).facetAddress(msg.sig);
    }
}