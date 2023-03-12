// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IAddressesProvider} from "./interfaces/IAddressesProvider.sol";
import {IDAO} from "./interfaces/dao/IDAO.sol";

/**
 * @title HabitatDiamond - DAO diamond contract (EIP 2535).
 * @author @roleengineer
 */
contract HabitatDiamond {
  /**
   * @notice Constructor function makes default DAO diamond cuts.
   * @param addressesProvider Address of the contract that is a trusted source of facets and init contract addresses.
   * @param daoMetaData Metadata struct which contains strings: daoName, purpose, info and socials.
   * @param msCallData Encoded data which will be used by the management system init contract to initialize state.
   *                   Encoding depends on the respective init function of the init contract and includes selector.
   *                   Management system init contract address is taken from addressesProvider contract.
   */
  constructor(
    address addressesProvider,
    IDAO.DAOMeta memory daoMetaData,
    bytes memory msCallData
  ) payable {
    LibDiamond.setContractOwner(msg.sender);
    // make a default cut
    IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
    // Add the diamondCut external function from the diamondCutFacet
    IAddressesProvider.Facet memory diamondCutFacet = IAddressesProvider(addressesProvider)
      .getDiamondCutFacet();

    cut[0] = IDiamondCut.FacetCut({
      facetAddress: diamondCutFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: diamondCutFacet.functionSelectors
    });

    // Add the default diamondOwnershipFacet - remove after governance is set
    IAddressesProvider.Facet memory diamondOwnershipFacet = IAddressesProvider(addressesProvider)
      .getOwnershipFacet();

    cut[1] = IDiamondCut.FacetCut({
      facetAddress: diamondOwnershipFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: diamondOwnershipFacet.functionSelectors
    });

    // Add the default diamondLoupeFacet
    IAddressesProvider.Facet memory diamondLoupeFacet = IAddressesProvider(addressesProvider)
      .getDiamondLoupeFacet();

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

    IAddressesProvider.Facet memory daoViewerFacet = IAddressesProvider(addressesProvider)
      .getDAOViewerFacet();
    cutDAO[0] = IDiamondCut.FacetCut({
      facetAddress: daoViewerFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: daoViewerFacet.functionSelectors
    });
    // hardcoded, but
    bytes memory daoInitCalldata = abi.encodeWithSignature(
      "initDAO(string,string,string,string,address)",
      daoMetaData.daoName,
      daoMetaData.purpose,
      daoMetaData.info,
      daoMetaData.socials,
      addressesProvider
    );
    LibDiamond.diamondCut(
      cutDAO,
      IAddressesProvider(addressesProvider).getDAOInit(),
      daoInitCalldata
    );

    IDiamondCut.FacetCut[] memory msCut = new IDiamondCut.FacetCut[](1);

    // Add the ManagementSystemFacet
    IAddressesProvider.Facet memory managementSystemFacet = IAddressesProvider(addressesProvider)
      .getManagementSystemFacet();

    msCut[0] = IDiamondCut.FacetCut({
      facetAddress: managementSystemFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: managementSystemFacet.functionSelectors
    });

    // make management system init
    address managementSystemInit = IAddressesProvider(addressesProvider).getManagementSystemsInit();

    LibDiamond.diamondCut(msCut, managementSystemInit, msCallData);
  }

  /**
   * @dev Find facet for function that is called and execute the
   *      function if a facet is found and return any value.
   */
  fallback() external payable {
    LibDiamond.DiamondStorage storage ds;
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    // get diamond storage
    assembly {
      ds.slot := position
    }
    // get facet from function selector
    address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
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
