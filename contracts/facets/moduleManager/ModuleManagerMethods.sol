// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {IDiamondCut} from "../../interfaces/IDiamondCut.sol";
import {LibHabitatDiamond} from "../../libraries/LibHabitatDiamond.sol";
import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";

/**
 * @title ModuleManagerMethods - Contract contains functions that implement module manager actions.
 * @dev TODO add events
 * @author @roleengineer
 */
contract ModuleManagerMethods {
  /**
   * @notice Module manager action - SwitchModuleDecider. Allows to switch `msName` module decider.
   * @param msName Module name, which decider should be switched.
   * @param newDecider The new `msName` module decider address.
   */
  function switchModuleDecider(string memory msName, address newDecider) external {
    LibManagementSystem._switchDeciderOfManagementSystem(msName, newDecider);
  }

  /**
   * @notice Module manager action - AddNewModule. Allows to add new `msName` module.
   * @param msName New module name.
   * @param decisionType New `msName` module decision type.
   * @param deciderAddress New `msName` module decider address.
   * @param facetAddresses An array of facet addresses, which provides new module functionality.
   * @param facetSelectors An array of selector array of facet addresses.
   */
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

  /**
   * @notice Module manager action - AddNewModuleAndStateUpdate. Allows to add
   *         new `msName` module and initialize state related to it.
   * @param msName New module name.
   * @param decisionType New `msName` module decision type.
   * @param deciderAddress New `msName` module decider address.
   * @param facetAddresses An array of facet addresses, which provides new module functionality.
   * @param facetSelectors An array of selector array of facet addresses.
   * @param initAddress Init contract address, which has function to initialize new module state.
   * @param _callData Data payload (with selector) for a init contract function to initialize new module state.
   */
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

  /**
   * @notice Module manager action - RemoveModule. Allows to remove `msName` module.
   * @param msName The name of module, which should be removed.
   */
  function removeModule(string memory msName) external {
    LibManagementSystem._removeManagementSystem(msName);
  }

  /**
   * @notice Module manager action - ChangeAddressesProvider. Allows to change addresses provider.
   * @dev AddressesProvider is a DAO trusted source of facets and init contracts.
   * @param newAddressesProvider Address of the addresses provider contract.
   */
  function changeAddressesProvider(address newAddressesProvider) external {
    LibHabitatDiamond.setAddressesProvider(newAddressesProvider);
  }

  /**
   * @notice Module manager action - DiamondCut. Allows to make EIP2535 diamond cut.
   * @dev AddressesProvider is a DAO trusted source of facets and init contracts.
   * @param _diamondCut An array of FacetCut structs. FacetCut struct contains:
   *                    facetAddress, uint8 action and an array of facet selectors.
   * @param _init Address of the init contract, which is responsible to initialize the state.
   * @param _calldata Data payload (with selector) for init contract function.
   */
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) external {
    LibHabitatDiamond.diamondCut(_diamondCut, _init, _calldata);
  }
}
