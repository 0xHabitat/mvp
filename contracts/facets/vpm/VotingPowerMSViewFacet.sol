// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystemVotingPower} from "../../libraries/decisionSystem/votingPower/LibManagementSystemVotingPower.sol";
import {LibVotingPower} from "../../libraries/decisionSystem/votingPower/LibVotingPower.sol";
import {IVotingPower} from "../../interfaces/IVotingPower.sol";

contract VotingPowerMSViewFacet {
  function minimumQuorumNumerator(string memory msName) external view returns (uint64) {
    return LibManagementSystemVotingPower._getMinimumQuorumNumerator(msName);
  }

  function thresholdForProposalNumerator(string memory msName) external view returns (uint64) {
    return LibManagementSystemVotingPower._getThresholdForProposalNumerator(msName);
  }

  function thresholdForInitiatorNumerator(string memory msName) external view returns (uint64) {
    return LibManagementSystemVotingPower._getThresholdForInitiatorNumerator(msName);
  }

  function denominator() external view returns (uint256) {
    return LibVotingPower._getPrecision();
  }

  function getMinimumQuorum(string memory msName) external view returns (uint256) {
    uint64 minimumQuorumNumerator = LibManagementSystemVotingPower._getMinimumQuorumNumerator(msName);
    return LibVotingPower._calculateMinimumQuorum(minimumQuorumNumerator);
  }

  function isQourum(string memory msName) external view returns (bool) {
    uint64 minimumQuorumNumerator = LibManagementSystemVotingPower._getMinimumQuorumNumerator(msName);
    return LibVotingPower._calculateIsQuorum(minimumQuorumNumerator);
  }

  function isEnoughVotingPower(address holder, string memory msName) external view returns (bool) {
    uint64 thresholdForInitiatorNumerator = LibManagementSystemVotingPower._getThresholdForInitiatorNumerator(msName);
    return LibVotingPower._calculateIsEnoughVotingPower(holder, thresholdForInitiatorNumerator);
  }

  function isProposalThresholdReached(uint256 amountOfVotes, string memory msName) external view returns (bool) {
    uint64 thresholdForProposal = LibManagementSystemVotingPower._getThresholdForProposalNumerator(msName);
    return LibVotingPower._calculateIsProposalThresholdReached(amountOfVotes, thresholdForProposal);
  }

  function getSecondsProposalVotingPeriod(string memory msName) external view returns(uint128) {
    return LibManagementSystemVotingPower._getSecondsProposalVotingPeriod(msName);
  }

  function getSecondsProposalExecutionDelayPeriod(string memory msName) external view returns(uint128) {
    return LibManagementSystemVotingPower._getSecondsProposalExecutionDelayPeriod(msName);
  }

  // functions related to specific ms

  // return ProposalVoting struct
  function getProposalVotingVotesYes(string memory msName, uint256 proposalId)
    external
    view
    returns (uint256)
  {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    IVotingPower.ProposalVoting storage proposalVoting = LibVotingPower._getProposalVoting(proposalKey);
    return proposalVoting.votesYes;
  }

  function getProposalVotingVotesNo(string memory msName, uint256 proposalId)
    external
    view
    returns (uint256)
  {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    IVotingPower.ProposalVoting storage proposalVoting = LibVotingPower._getProposalVoting(proposalKey);
    return proposalVoting.votesNo;
  }

  function getProposalVotingDeadlineTimestamp(string memory msName, uint256 proposalId)
    external
    view
    returns (uint256)
  {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    IVotingPower.ProposalVoting storage proposalVoting = LibVotingPower._getProposalVoting(proposalKey);
    return proposalVoting.votingEndTimestamp;
  }

  function isHolderVotedForProposal(string memory msName, uint256 proposalId, address holder)
    external
    view
    returns (bool)
  {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    IVotingPower.ProposalVoting storage proposalVoting = LibVotingPower._getProposalVoting(proposalKey);
    return proposalVoting.votedAmount[holder] > 0;
  }

  function isVotingForProposalStarted(string memory msName, uint256 proposalId) external view returns (bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    IVotingPower.ProposalVoting storage proposalVoting = LibVotingPower._getProposalVoting(proposalKey);
    return proposalVoting.votingStarted;
  }

}
