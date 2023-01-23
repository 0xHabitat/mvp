// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {LibHabitatDiamond} from "../../libraries/LibHabitatDiamond.sol";

// TODO add view functions
contract ManagementSystemFacet {
  function getManagementSystemsPosition() external pure returns (bytes32) {
    return LibManagementSystem._getManagementSystemsPosition();
  }

  function getManagementSystemsHumanReadable() external view returns(IManagementSystem.ManagementSystem[] memory) {
    return LibManagementSystem._getManagementSystemsHR();
  }

  function getModuleNames() external view returns(string[] memory moduleNames) {
    return LibManagementSystem._getModuleNames();
  }

  function getDecider(string memory msName) external view returns(address) {
    return LibManagementSystem._getDecider(msName);
  }

  function getAddressesProvider() external view returns(address) {
    return LibHabitatDiamond.getAddressesProvider();
  }

}
