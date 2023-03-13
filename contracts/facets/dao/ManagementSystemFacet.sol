// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {LibHabitatDiamond} from "../../libraries/LibHabitatDiamond.sol";

/**
 * @title ManagementSystemFacet - Facet provides view functions related to the core
 *                  of the DAO diamond - management system, which contains modules.
 * @dev TODO add view functions
 * @author @roleengineer
 */
contract ManagementSystemFacet {
  /**
   * @notice Returns DAO diamond contract storage position, where management systems are stored.
   */
  function getManagementSystemsPosition() external pure returns (bytes32) {
    return LibManagementSystem._getManagementSystemsPosition();
  }

  /**
   * @notice Returns an array, contains structs of all modules.
   *         Module struct contains: module name (string), module decision type (uint8),
   *         module current decider (address), module data position (bytes32).
   */
  function getManagementSystemsHumanReadable()
    external
    view
    returns (IManagementSystem.ManagementSystem[] memory)
  {
    return LibManagementSystem._getManagementSystemsHR();
  }

  /**
   * @notice Returns an array, contains all module names.
   */
  function getModuleNames() external view returns (string[] memory) {
    return LibManagementSystem._getModuleNames();
  }

  /**
   * @notice Returns current decider address by `msName`.
   * @dev Each module has its own decider, modules could have same decider.
   * @param msName DAO Module name
   * @return Module current decider contract address
   */
  function getModuleDecider(string memory msName) external view returns (address) {
    return LibManagementSystem._getDecider(msName);
  }

  /**
   * @notice Returns addresses provider.
   * @dev Address of the contract that is a trusted source of facets and init contract addresses.
   */
  function getAddressesProvider() external view returns (address) {
    return LibHabitatDiamond.getAddressesProvider();
  }
}
