// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../libraries/dao/LibManagementSystem.sol";
import {IManagementSystem} from "../interfaces/dao/IManagementSystem.sol";

contract ManagementSystemsInit {

  function initManagementSystems5(
    IManagementSystem.DecisionType[] memory decisionTypes
  ) external {
    IManagementSystem.ManagementSystems storage mss = LibManagementSystem._getManagementSystems();
    mss.numberOfManagementSystems = 5;
    mss.setAddChangeManagementSystem = IManagementSystem.ManagementSystem({
      nameMS: "setAddChangeManagementSystem",
      decisionType: decisionTypes[0],
      dataPosition: keccak256(abi.encodePacked(address(this), "managementSystem", "setAddChangeManagementSystem", uint(0)))
    });
    mss.governance = IManagementSystem.ManagementSystem({
      nameMS: "governance",
      decisionType: decisionTypes[1],
      dataPosition: keccak256(abi.encodePacked(address(this), "managementSystem", "governance", uint(1)))
    });
    mss.treasury = IManagementSystem.ManagementSystem({
      nameMS: "treasury",
      decisionType: decisionTypes[2],
      dataPosition: keccak256(abi.encodePacked(address(this), "managementSystem", "treasury", uint(2)))
    });
    mss.subDAOsCreation = IManagementSystem.ManagementSystem({
      nameMS: "subDAOsCreation",
      decisionType: decisionTypes[3],
      dataPosition: keccak256(abi.encodePacked(address(this), "managementSystem", "subDAOsCreation", uint(3)))
    });
    mss.launchPad = IManagementSystem.ManagementSystem({
      nameMS: "launchPad",
      decisionType: decisionTypes[4],
      dataPosition: keccak256(abi.encodePacked(address(this), "managementSystem", "launchPad", uint(4)))
    });
  }
}
