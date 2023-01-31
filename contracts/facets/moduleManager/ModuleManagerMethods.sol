// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {IDiamondCut} from "../../interfaces/IDiamondCut.sol";
import {LibHabitatDiamond} from "../../libraries/LibHabitatDiamond.sol";
import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";

// TODO add events
contract ModuleManagerMethods {
  // Module manager actions
  function switchModuleDecider(string memory msName, address newDecider) external {
    LibManagementSystem._switchDeciderOfManagementSystem(msName, newDecider);
  }

  function addNewModuleWithFacets(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    address deciderAddress,
    address[] memory facetAddresses,
    bytes4[][] memory facetSelectors
  ) external {
    LibManagementSystem._setNewManagementSystem(msName, decisionType, deciderAddress);
    LibHabitatDiamond.addFacets(facetAddresses, facetSelectors);
  }

  function addNewModuleWithFacetsAndStateUpdate(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    address deciderAddress,
    address[] memory facetAddresses,
    bytes4[][] memory facetSelectors,
    address initAddress,
    bytes memory _callData
  ) external {
    LibManagementSystem._setNewManagementSystem(msName, decisionType, deciderAddress);
    LibHabitatDiamond.addFacets(facetAddresses, facetSelectors);
    LibHabitatDiamond.updateState(initAddress, _callData);
  }

  function removeModule(string memory msName) external {
    LibManagementSystem._removeManagementSystem(msName);
  }

  function changeAddressesProvider(address newAddressesProvider) external {
    LibHabitatDiamond.setAddressesProvider(newAddressesProvider);
  }

  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) external {
    LibHabitatDiamond.diamondCut(_diamondCut, _init, _calldata);
  }

}
