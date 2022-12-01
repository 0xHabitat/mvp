// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDecisionSystemSpecificData} from "../../libraries/decisionSystem/LibDecisionSystemSpecificData.sol";

contract SpecificDataFacet {

  function thresholdForProposalNumerator(string memory msName) external view returns (uint256) {
    return LibDecisionSystemSpecificData._getThresholdForProposalNumerator(msName);
  }

  function thresholdForInitiatorNumerator(string memory msName) external view returns (uint256) {
    return LibDecisionSystemSpecificData._getThresholdForInitiatorNumerator(msName);
  }

  function getSecondsProposalVotingPeriod(string memory msName) external view returns(uint256) {
    return LibDecisionSystemSpecificData._getSecondsProposalVotingPeriod(msName);
  }

  function getSecondsProposalExecutionDelayPeriodVP(string memory msName) external view returns(uint256) {
    return LibDecisionSystemSpecificData._getSecondsProposalExecutionDelayPeriodVP(msName);
  }

  function getSecondsProposalExecutionDelayPeriodSigners(string memory msName) external view returns(uint256) {
    return LibDecisionSystemSpecificData._getSecondsProposalExecutionDelayPeriodSigners(msName);
  }
}
