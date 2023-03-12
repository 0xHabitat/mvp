// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../libraries/dao/LibManagementSystem.sol";
import {IManagementSystem} from "../interfaces/dao/IManagementSystem.sol";

/**
 * @title ManagementSystemsInit - Init contract that initialize the DAO core,
 *                                sets modules (their names and deciders).
 * @author @roleengineer
 */
contract ManagementSystemsInit {
  /**
   * @notice Method initiates DAO modules.
   * @param msNames An array of module names.
   * @param decisionTypes An array of module default decision types (uint8).
   * @param deciders An array of module default decider contracts.
   */
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
