// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "../dao/LibManagementSystem.sol";

// decisionSpecificData[2]
struct VotingPowerSpecificData {
  uint64 thresholdForInitiator;
  uint64 thresholdForProposal;
  uint64 secondsProposalVotingPeriod;
  uint64 secondsProposalExecutionDelayPeriod;
}

library LibDecisionSystemSpecificData {

  // Voting Power specific data getters - maybe better move to LibMS?

  function _getMSVotingPowerSpecificData(string memory msName) internal returns(VotingPowerSpecificData memory vpsd) {
    IManagementSystem.MSData storage msData = LibManagementSystem._getMSDataByName(msName);
    bytes memory specificData = msData.decisionSpecificData[IManagementSystem.DecisionType(2)];
    vpsd = abi.decode(specificData, (VotingPowerSpecificData));
  }

  function _getMSVotingPowerSpecificDataStoragePointer(string memory msName) internal returns(bytes storage vpsd) {
    IManagementSystem.MSData storage msData = LibManagementSystem._getMSDataByName(msName);
    vpsd = msData.decisionSpecificData[IManagementSystem.DecisionType(2)];
  }

  // Voting Power specific data view functions

  function _getThresholdForProposalNumerator(string memory msName) internal returns(uint64) {
    VotingPowerSpecificData memory vpsd = _getMSVotingPowerSpecificData(msName);
    return vpsd.thresholdForProposal;
  }

  function _getThresholdForInitiatorNumerator(string memory msName) internal returns(uint64) {
    VotingPowerSpecificData memory vpsd = _getMSVotingPowerSpecificData(msName);
    return vpsd.thresholdForInitiator;
  }

  function _getSecondsProposalVotingPeriod(string memory msName) internal returns(uint64) {
    VotingPowerSpecificData memory vpsd = _getMSVotingPowerSpecificData(msName);
    return vpsd.secondsProposalVotingPeriod;
  }

  function _getSecondsProposalExecutionDelayPeriod(string memory msName) internal returns(uint64) {
    VotingPowerSpecificData memory vpsd = _getMSVotingPowerSpecificData(msName);
    return vpsd.secondsProposalExecutionDelayPeriod;
  }
}
