// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { ERC165Storage } from "@solidstate/contracts/introspection/ERC165Storage.sol";
import { IDiamondLoupe } from "@solidstate/contracts/proxy/diamond/IDiamondLoupe.sol";
import { IDiamondCuttable } from "@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol";
import { IERC173 } from "@solidstate/contracts/access/IERC173.sol";
import { IERC165 } from "@solidstate/contracts/introspection/IERC165.sol";
import { RepositoryStorage } from "contracts/storage/RepositoryStorage.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

address constant habitatRepo = address(0); // replace with Habitat RepoAddr

contract DiamondInit {    
    using ERC165Storage for ERC165Storage.Layout;
    using RepositoryStorage for RepositoryStorage.Layout;

    // You can add parameters to this function in order to pass in 
    // data to set your own state variables
    function init() external {
        // adding ERC165 data
        ERC165Storage.Layout storage l = ERC165Storage.layout();
        l.supportedInterfaces[type(IERC165).interfaceId] = true;
        l.supportedInterfaces[type(IDiamondCuttable).interfaceId] = true;
        l.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        l.supportedInterfaces[type(IERC173).interfaceId] = true;

        // RepoStorage.Layout storage r = RepoStorage.layout();
        // r.repo = habitatRepo;

        // add your own state variables 
        // EIP-2535 specifies that the `diamondCut` function takes two optional 
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface 
    }


}