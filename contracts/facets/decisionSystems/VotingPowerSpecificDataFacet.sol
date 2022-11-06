// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDecisionSystemSpecificData} from "../../libraries/decisionSystem/LibDecisionSystemSpecificData.sol";

contract VotingPowerSpecificDataFacet {

  function thresholdForProposalNumerator(string memory msName) external returns (uint64) {
    return LibDecisionSystemSpecificData._getThresholdForProposalNumerator(msName);
  }

  function thresholdForInitiatorNumerator(string memory msName) external returns (uint64) {
    return LibDecisionSystemSpecificData._getThresholdForInitiatorNumerator(msName);
  }

  function getSecondsProposalVotingPeriod(string memory msName) external returns(uint128) {
    return LibDecisionSystemSpecificData._getSecondsProposalVotingPeriod(msName);
  }

  function getSecondsProposalExecutionDelayPeriod(string memory msName) external returns(uint128) {
    return LibDecisionSystemSpecificData._getSecondsProposalExecutionDelayPeriod(msName);
  }
}
