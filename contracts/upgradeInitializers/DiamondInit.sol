// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC165, ERC165Storage } from '@solidstate/contracts/introspection/ERC165.sol';
import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';
import { IDiamondWritable } from '@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol';
import { ISafeOwnable } from '@solidstate/contracts/access/ownable/ISafeOwnable.sol';

contract XpmInit {    
    using ERC165Storage for ERC165Storage.Layout;
    function init() external {
        ERC165Storage.Layout storage l = ERC165Storage.layout();

        l.supportedInterfaces[type(IDiamondWritable).interfaceId] = true;
        l.supportedInterfaces[type(IDiamondReadable).interfaceId] = true;
        l.supportedInterfaces[type(ISafeOwnable).interfaceId] = true;
        l.supportedInterfaces[type(IERC165).interfaceId] = true;

        
    }
}