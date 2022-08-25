// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystemVotingPower} from "../../libraries/decisionSystem/votingPower/LibManagementSystemVotingPower.sol";
import {LibVotingPower} from "../../libraries/decisionSystem/votingPower/LibVotingPower.sol";

contract VotingPowerMSViewFacet {
  function minimumQuorumNumerator(string memory msName) external returns (uint64) {
    return LibManagementSystemVotingPower._getMinimumQuorumNumerator(msName);
  }

  function thresholdForProposalNumerator(string memory msName) external returns (uint64) {
    return LibManagementSystemVotingPower._getThresholdForProposalNumerator(msName);
  }

  function thresholdForInitiatorNumerator(string memory msName) external returns (uint64) {
    return LibManagementSystemVotingPower._getThresholdForInitiatorNumerator(msName);
  }

  function denominator() external view returns (uint256) {
    return LibVotingPower._getPrecision();
  }

  function getMinimumQuorum(string memory msName) external returns (uint256) {
    uint64 minimumQuorumNumerator = LibManagementSystemVotingPower._getMinimumQuorumNumerator(msName);
    return LibVotingPower._calculateMinimumQuorum(minimumQuorumNumerator);
  }

  function isQourum(string memory msName) external returns (bool) {
    uint64 minimumQuorumNumerator = LibManagementSystemVotingPower._getMinimumQuorumNumerator(msName);
    return LibVotingPower._calculateIsQuorum(minimumQuorumNumerator);
  }

  function isEnoughVotingPower(address holder, string memory msName) external returns (bool) {
    uint64 thresholdForInitiatorNumerator = LibManagementSystemVotingPower._getThresholdForInitiatorNumerator(msName);
    return LibVotingPower._calculateIsEnoughVotingPower(holder, thresholdForInitiatorNumerator);
  }

  function isProposalThresholdReached(uint256 amountOfVotes, string memory msName) external returns (bool) {
    uint64 thresholdForProposal = LibManagementSystemVotingPower._getThresholdForProposalNumerator(msName);
    return LibVotingPower._calculateIsProposalThresholdReached(amountOfVotes, thresholdForProposal);
  }

  function getSecondsProposalVotingPeriod(string memory msName) external returns(uint128) {
    return LibManagementSystemVotingPower._getSecondsProposalVotingPeriod(msName);
  }

  function getSecondsProposalExecutionDelayPeriod(string memory msName) external returns(uint128) {
    return LibManagementSystemVotingPower._getSecondsProposalExecutionDelayPeriod(msName);
  }

  // functions related to specific ms

}
