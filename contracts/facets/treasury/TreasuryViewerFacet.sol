// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { ITreasury } from "../../interfaces/treasury/ITreasury.sol";
import { LibTreasury } from "../../libraries/LibTreasury.sol";

contract TreasuryViewerFacet is ITreasury {

  function getVotingType() external view override returns(VotingType) {
    return LibTreasury.treasuryStorage().votingType;
  }

  function getTreasuryMaxDuration() external view override returns(uint128) {
    return LibTreasury.treasuryStorage().maxDuration;
  }

  function getProposalsCount() external view override returns(uint128) {
    return LibTreasury.treasuryStorage().proposalsCount;
  }

  function getActiveProposalsIds() external view override returns(uint[] memory) {
    return LibTreasury.treasuryStorage().activeProposalsIds;
  }

  function getTreasuryProposal(uint proposalId) external view override returns(Proposal memory) {
    return LibTreasury._getTreasuryProposal(proposalId);
  }
  // return ProposalVoting struct
  function getTreasuryProposalVotingVotesYes(uint proposalId) external view override returns(uint) {
    return LibTreasury._getTreasuryProposalVoting(proposalId).votesYes;
  }
  function getTreasuryProposalVotingVotesNo(uint proposalId) external view override returns(uint) {
    return LibTreasury._getTreasuryProposalVoting(proposalId).votesNo;
  }
  function getTreasuryProposalVotingDeadlineTimestamp(uint proposalId) external view override returns(uint) {
    return LibTreasury._getTreasuryProposalVoting(proposalId).deadlineTimestamp;
  }
  function isHolderVotedForProposal(uint proposalId, address holder) external view override returns(bool) {
    return LibTreasury._getTreasuryProposalVoting(proposalId).voted[holder];
  }
  function isVotingForProposalStarted(uint proposalId) external view override returns(bool) {
    return LibTreasury._getTreasuryProposalVoting(proposalId).votingStarted;
  }

}
