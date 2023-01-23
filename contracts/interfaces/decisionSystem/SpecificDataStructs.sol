// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// decisionSpecificData[2]
struct VotingPowerSpecificData {
  uint256 thresholdForInitiator;
  uint256 thresholdForProposal;
  uint256 secondsProposalVotingPeriod;
  uint256 secondsProposalExecutionDelayPeriod;
}
// decisionSpecificData[3]
struct SignerSpecificData {
  uint256 secondsProposalExecutionDelayPeriod;
}
