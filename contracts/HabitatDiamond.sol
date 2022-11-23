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
import {IAddressesProvider} from "./interfaces/IAddressesProvider.sol";
import {IDAO} from "./interfaces/dao/IDAO.sol";
import {IManagementSystem} from "./interfaces/dao/IManagementSystem.sol";

contract HabitatDiamond {
  constructor(
    address _contractOwner,
    address addressesProvider,
    IDAO.DAOMeta memory daoMetaData
  ) payable {
    LibDiamond.setContractOwner(_contractOwner);
    // make a default cut
    IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
    // Add the diamondCut external function from the diamondCutFacet
    IAddressesProvider.Facet memory diamondCutFacet = IAddressesProvider(addressesProvider).getDiamondCutFacet();

    cut[0] = IDiamondCut.FacetCut({
      facetAddress: diamondCutFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: diamondCutFacet.functionSelectors
    });

    // Add the default diamondOwnershipFacet - remove after governance is set
    IAddressesProvider.Facet memory diamondOwnershipFacet = IAddressesProvider(addressesProvider).getOwnershipFacet();

    cut[1] = IDiamondCut.FacetCut({
      facetAddress: diamondOwnershipFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: diamondOwnershipFacet.functionSelectors
    });

    // Add the default diamondLoupeFacet
    IAddressesProvider.Facet memory diamondLoupeFacet = IAddressesProvider(addressesProvider).getDiamondLoupeFacet();

    cut[2] = IDiamondCut.FacetCut({
      facetAddress: diamondLoupeFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: diamondLoupeFacet.functionSelectors
    });

    address defaultDiamondInit = IAddressesProvider(addressesProvider).getDiamondInit();
    bytes memory callData = abi.encodeWithSignature("init()");
    LibDiamond.diamondCut(cut, defaultDiamondInit, callData);

    // DAO first
    IDiamondCut.FacetCut[] memory cutDAO = new IDiamondCut.FacetCut[](1); // when have more dao related facets than extend an array
    address daoInit = IAddressesProvider(addressesProvider).getDAOInit();
    IAddressesProvider.Facet memory daoViewerFacet = IAddressesProvider(addressesProvider).getDAOViewerFacet();
    cutDAO[0] = IDiamondCut.FacetCut({
      facetAddress: daoViewerFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: daoViewerFacet.functionSelectors
    });
    // hardcoded, but
    bytes memory daoInitCalldata = abi.encodeWithSignature(
      'initDAO(string,string,string,string,address)',
      daoMetaData.daoName,
      daoMetaData.purpose,
      daoMetaData.info,
      daoMetaData.socials,
      addressesProvider
    );
    LibDiamond.diamondCut(cutDAO, daoInit, daoInitCalldata);
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
