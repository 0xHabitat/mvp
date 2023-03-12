// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {IProposal} from "../../interfaces/IProposal.sol";

/**
 * @title ModuleViewerFacet - Facet provides view functions related to the DAO modules.
 * @author @roleengineer
 */
contract ModuleViewerFacet {
  /**
   * @notice Returns current module decision type.
   * @param msName Module name
   */
  function getModuleDecisionType(
    string memory msName
  ) external view returns (IManagementSystem.DecisionType) {
    return LibManagementSystem._getDecisionType(msName);
  }

  /**
   * @notice Returns module proposal counter.
   * @param msName Module name proposal counter is related to.
   */
  function getModuleProposalsCount(string memory msName) external view returns (uint256) {
    return LibManagementSystem._getProposalsCount(msName);
  }

  /**
   * @notice Returns an array of active proposal ids.
   * @dev Active proposal is created one, but still without final decision.
   * @param msName Module name proposals are related to.
   */
  function getModuleActiveProposalsIds(
    string memory msName
  ) external view returns (uint256[] memory) {
    return LibManagementSystem._getActiveProposalsIds(msName);
  }

  /**
   * @notice Returns an array of accepted proposal ids.
   * @dev Accepted proposal got positive decision, but still waiting execution.
   * @param msName Module name proposals are related to.
   */
  function getModuleAcceptedProposalsIds(
    string memory msName
  ) external view returns (uint256[] memory) {
    return LibManagementSystem._getAcceptedProposalsIds(msName);
  }

  /**
   * @notice Returns struct that describes the proposal.
   * @param msName Module name proposal is related to.
   * @param proposalId The id of the proposal.
   * @return Proposal struct contains:
   *                proposalAccepted - True, if propopal is accepted;
   *                destinationAddress - Address to call to execute proposal;
   *                value - The amount of ETH is being sent;
   *                callData - Data payload (contains selector);
   *                proposalExecuted - False, if proposal is not executed yet;
   *                executionTimestamp - Timestamp to be able to execute proposal;
   */
  function getModuleProposal(
    string memory msName,
    uint256 proposalId
  ) external view returns (IProposal.Proposal memory) {
    return LibManagementSystem._getProposal(msName, proposalId);
  }
}
