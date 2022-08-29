// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";

contract Diamond {
  constructor(address _contractOwner, address _diamondCutFacet, address _diamondLoupeFacet) payable {        
    LibDiamond.setContractOwner(_contractOwner);

    // Add the diamondCut external function from the diamondCutFacet
    IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

    // cut diamondCut
    bytes4[] memory functionSelectors1 = new bytes4[](1);
    functionSelectors1[0] = IDiamondCut.diamondCut.selector;
    cut[0] = IDiamondCut.FacetCut({
        facetAddress: _diamondCutFacet, 
        action: IDiamondCut.FacetCutAction.Add, 
        functionSelectors: functionSelectors1
    });

    // cut diamondLoupe
    bytes4[] memory functionSelectors2 = new bytes4[](4);
    functionSelectors2[0] = IDiamondLoupe.facets.selector;
    functionSelectors2[1] = IDiamondLoupe.facetFunctionSelectors.selector;
    functionSelectors2[2] = IDiamondLoupe.facetAddresses.selector;
    functionSelectors2[3] = IDiamondLoupe.facetAddress.selector;
    cut[1] = IDiamondCut.FacetCut({
        facetAddress: _diamondLoupeFacet, 
        action: IDiamondCut.FacetCutAction.Add, 
        functionSelectors: functionSelectors2
    });

    LibDiamond.diamondCut(cut, address(0), "");    
  }

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  fallback() external payable {
    LibDiamond.DiamondStorage storage ds;
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    // get diamond storage
    assembly {
      ds.slot := position
    }
    // get facet from function selector
    address facet = address(bytes20(ds.facets[msg.sig]));
    require(facet != address(0), "Diamond: Function does not exist");
    // Execute external function from facet using delegatecall and return any value.
    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())
      // execute function call using the facet
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
      // get any return value
      returndatacopy(0, 0, returndatasize())
      // return any return value or error back to the caller
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
