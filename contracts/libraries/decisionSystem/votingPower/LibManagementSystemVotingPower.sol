// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IProposal} from "../../../interfaces/IProposal.sol";
import {IManagementSystem} from "../../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "../../dao/LibManagementSystem.sol";

// decisionSpecificData[2]
struct VotingPowerSpecificData {
  uint64 thresholdForProposal;
  uint64 thresholdForInitiator;
  uint64 secondsProposalVotingPeriod;
  uint64 secondsProposalExecutionDelayPeriod;
}

library LibManagementSystemVotingPower {

  function _getManagementSystemData(string memory msName) internal returns(IManagementSystem.MSData storage msData) {
    IManagementSystem.ManagementSystem memory ms = LibManagementSystem._getManagementSystem(msName);
    require(ms.decisionType == IManagementSystem.DecisionType(2), "Decision type is not a voting power erc20");
    require(ms.dataPosition != bytes32(0), "Mananagement system is not set.");
    msData = LibManagementSystem._getMSData(ms.dataPosition);
  }

  function _getMSVotingPowerSpecificData(string memory msName) internal returns(VotingPowerSpecificData memory vpsd) {
    IManagementSystem.MSData storage msData = _getManagementSystemData(msName);
    vpsd = convertSpecificDataBytesToVPStruct(msData.decisionSpecificData[IManagementSystem.DecisionType(2)]);
  }

  function convertSpecificDataBytesToVPStruct(bytes memory specificData) internal pure returns (VotingPowerSpecificData memory) {
    return abi.decode(specificData, (VotingPowerSpecificData));
  }

  function _getMSVotingPowerSpecificDataStoragePointer(string memory msName) internal returns(bytes storage vpsd) {
    IManagementSystem.MSData storage msData = _getManagementSystemData(msName);
    vpsd = msData.decisionSpecificData[IManagementSystem.DecisionType(2)];
  }

  function _getFreeProposalId(string memory msName) internal returns(uint256 proposalId) {
    IManagementSystem.MSData storage msData = _getManagementSystemData(msName);
    require(msData.activeVotingProposalsIds.length < 200, "No more proposals pls");
    msData.proposalsCounter = msData.proposalsCounter + uint128(1);
    proposalId = uint256(msData.proposalsCounter);
    msData.activeVotingProposalsIds.push(proposalId);
  }

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

  function _getProposal(string memory msName, uint proposalId) internal returns(IProposal.Proposal storage p) {
    IManagementSystem.MSData storage msData = _getManagementSystemData(msName);
    p = msData.proposals[proposalId];
  }

  function _getActiveVotingProposalsIds(string memory msName) internal returns(uint256[] storage) {
    IManagementSystem.MSData storage msData = _getManagementSystemData(msName);
    return msData.activeVotingProposalsIds;
  }

  function _getAcceptedProposalsIds(string memory msName) internal returns(uint256[] storage) {
    IManagementSystem.MSData storage msData = _getManagementSystemData(msName);
    return msData.acceptedProposalsIds;
  }

  function _removeProposalIdFromActiveVoting(string memory msName, uint256 proposalId) internal {
    uint256[] storage activeVotingProposalsIds = _getActiveVotingProposalsIds(msName);
    require(activeVotingProposalsIds.length > 0, "No active proposals.");
    if (activeVotingProposalsIds[activeVotingProposalsIds.length - 1] == proposalId) {
      activeVotingProposalsIds.pop();
    } else {
      // try to find array index
      uint256 indexId;
      for (uint256 index = 0; index < activeVotingProposalsIds.length; index++) {
        if (activeVotingProposalsIds[index] == proposalId) {
          indexId = index;
        }
      }
      // replace last
      activeVotingProposalsIds[indexId] = activeVotingProposalsIds[activeVotingProposalsIds.length - 1];
      activeVotingProposalsIds[activeVotingProposalsIds.length - 1] = proposalId;
      activeVotingProposalsIds.pop();
    }
  }

  function _removeProposal(string memory msName, uint256 proposalId) internal {
    IProposal.Proposal storage proposal = _getProposal(msName, proposalId);
    delete proposal.proposalAccepted;
    delete proposal.destinationAddress;
    delete proposal.value;
    delete proposal.callData;
    delete proposal.proposalExecuted;
    delete proposal.executionTimestamp;
  }

  function _addProposalIdToAccepted(string memory msName, uint proposalId) internal {
    uint[] storage acceptedProposalsIds = _getAcceptedProposalsIds(msName);
    acceptedProposalsIds.push(proposalId);
  }

  function _removePropopalIdFromAcceptedList(string memory msName, uint proposalId) internal {
    uint[] storage acceptedProposalsIds = _getAcceptedProposalsIds(msName);
    require(acceptedProposalsIds.length > 0, "No accepted proposals.");
    if (acceptedProposalsIds[acceptedProposalsIds.length - 1] == proposalId) {
      acceptedProposalsIds.pop();
    } else {
      // try to find array index
      uint256 indexId;
      for (uint256 index = 0; index < acceptedProposalsIds.length; index++) {
        if (acceptedProposalsIds[index] == proposalId) {
          indexId = index;
        }
      }
      // replace last
      acceptedProposalsIds[indexId] = acceptedProposalsIds[acceptedProposalsIds.length - 1];
      acceptedProposalsIds[acceptedProposalsIds.length - 1] = proposalId;
      acceptedProposalsIds.pop();
    }
  }
}
