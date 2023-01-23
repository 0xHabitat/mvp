// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "../dao/LibManagementSystem.sol";
import {VotingPowerSpecificData, SignerSpecificData} from "../../interfaces/decisionSystem/SpecificDataStructs.sol";

library LibDecisionSystemSpecificData {

  function _getMSVotingPowerSpecificData(string memory msName) internal view returns(VotingPowerSpecificData memory vpsd) {
    IManagementSystem.MSData storage msData = LibManagementSystem._getMSDataByName(msName);
    bytes memory specificData = msData.decisionSpecificData[IManagementSystem.DecisionType(2)];
    vpsd = abi.decode(specificData, (VotingPowerSpecificData));
  }

  function _getMSSignersSpecificData(string memory msName) internal view returns(SignerSpecificData memory ssd) {
    IManagementSystem.MSData storage msData = LibManagementSystem._getMSDataByName(msName);
    bytes memory specificData = msData.decisionSpecificData[IManagementSystem.DecisionType(3)];
    ssd = abi.decode(specificData, (SignerSpecificData));
  }

  // specific data view functions
  function _getSecondsProposalExecutionDelayPeriodSigners(string memory msName) internal view returns(uint256) {
    SignerSpecificData memory ssd = _getMSSignersSpecificData(msName);
    return ssd.secondsProposalExecutionDelayPeriod;
  }

  function _getThresholdForProposalNumerator(string memory msName) internal view returns(uint256) {
    VotingPowerSpecificData memory vpsd = _getMSVotingPowerSpecificData(msName);
    return vpsd.thresholdForProposal;
  }

  function _getThresholdForInitiatorNumerator(string memory msName) internal view returns(uint256) {
    VotingPowerSpecificData memory vpsd = _getMSVotingPowerSpecificData(msName);
    return vpsd.thresholdForInitiator;
  }

  function _getSecondsProposalVotingPeriod(string memory msName) internal view returns(uint256) {
    VotingPowerSpecificData memory vpsd = _getMSVotingPowerSpecificData(msName);
    return vpsd.secondsProposalVotingPeriod;
  }

  function _getSecondsProposalExecutionDelayPeriodVP(string memory msName) internal view returns(uint256) {
    VotingPowerSpecificData memory vpsd = _getMSVotingPowerSpecificData(msName);
    return vpsd.secondsProposalExecutionDelayPeriod;
  }

  function _changedThresholdForInitiatorBytes(string memory msName, uint256 newThresholdForInitiator) internal view returns(bytes memory newVPSD) {
    VotingPowerSpecificData memory vpsd = LibDecisionSystemSpecificData._getMSVotingPowerSpecificData(msName);
    vpsd.thresholdForInitiator = newThresholdForInitiator;
    newVPSD = abi.encode(vpsd);
  }

  function _changedThresholdForProposalBytes(string memory msName, uint256 newThresholdForProposal) internal view returns(bytes memory newVPSD) {
    VotingPowerSpecificData memory vpsd = LibDecisionSystemSpecificData._getMSVotingPowerSpecificData(msName);
    vpsd.thresholdForProposal = newThresholdForProposal;
    newVPSD = abi.encode(vpsd);
  }

  function _changedSecondsProposalVotingPeriodBytes(string memory msName, uint256 newSecondsProposalVotingPeriod) internal view returns(bytes memory newVPSD) {
    VotingPowerSpecificData memory vpsd = LibDecisionSystemSpecificData._getMSVotingPowerSpecificData(msName);
    vpsd.secondsProposalVotingPeriod = newSecondsProposalVotingPeriod;
    newVPSD = abi.encode(vpsd);
  }

  function _changedSecondsProposalExecutionDelayPeriodVPBytes(string memory msName, uint256 newSecondsProposalExecutionDelayPeriodVP) internal view returns(bytes memory newVPSD) {
    VotingPowerSpecificData memory vpsd = LibDecisionSystemSpecificData._getMSVotingPowerSpecificData(msName);
    vpsd.secondsProposalExecutionDelayPeriod = newSecondsProposalExecutionDelayPeriodVP;
    newVPSD = abi.encode(vpsd);
  }

  function _changedSecondsProposalExecutionDelayPeriodSignersBytes(string memory msName, uint256 newSecondsProposalExecutionDelayPeriodSigners) internal view returns(bytes memory newSSD) {
    SignerSpecificData memory ssd = LibDecisionSystemSpecificData._getMSSignersSpecificData(msName);
    ssd.secondsProposalExecutionDelayPeriod = newSecondsProposalExecutionDelayPeriodSigners;
    newSSD = abi.encode(ssd);
  }
}
