// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {IProposal} from "../../interfaces/IProposal.sol";

contract ModuleViewerFacet {

  function getModuleDecisionType(string memory msName) external view returns (IManagementSystem.DecisionType) {
    return LibManagementSystem._getDecisionType(msName);
  }

  function getModuleProposalsCount(string memory msName) external view returns (uint256) {
    return LibManagementSystem._getProposalsCount(msName);
  }

  function getModuleActiveProposalsIds(string memory msName) external view returns (uint256[] memory) {
    return LibManagementSystem._getActiveProposalsIds(msName);
  }

  function getModuleAcceptedProposalsIds(string memory msName) external view returns (uint256[] memory) {
    return LibManagementSystem._getAcceptedProposalsIds(msName);
  }

  function getModuleProposal(string memory msName, uint256 proposalId)
    external
    view
    returns (IProposal.Proposal memory)
  {
    return LibManagementSystem._getProposal(msName, proposalId);
  }
}
