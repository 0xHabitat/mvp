// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../libraries/dao/LibManagementSystem.sol";
import {IManagementSystem} from "../interfaces/dao/IManagementSystem.sol";

contract ManagementSystemsInit {
  function initManagementSystems(
    string[] memory msNames,
    IManagementSystem.DecisionType[] memory decisionTypes,
    address[] memory deciders
  ) external {
    uint256 numberOfManagementSystems = msNames.length;
    require(
      decisionTypes.length == numberOfManagementSystems &&
        deciders.length == numberOfManagementSystems,
      "Input is incorrect, check arrays length."
    );
    for (uint256 i = 0; i < numberOfManagementSystems; i++) {
      LibManagementSystem._setNewManagementSystem(msNames[i], decisionTypes[i], deciders[i]);
    }
  }
}
