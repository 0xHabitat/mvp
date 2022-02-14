// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITreasury } from "../../interfaces/treasury/ITreasury.sol";
import { LibTreasury } from "../../libraries/LibTreasury.sol";

contract TreasuryViewerFacet {

  function getTreasuryProposal(uint proposalId) external view returns(ITreasury.Proposal memory) {
    return LibTreasury._getTreasuryProposal(proposalId);
  }
  // return ProposalVoting struct
  function getTreasuryProposalVotingVotesYes(uint proposalId) external view returns(uint) {
    return LibTreasury._getTreasuryProposalVoting(proposalId).votesYes;
  }
  function getTreasuryProposalVotingVotesNo(uint proposalId) external view returns(uint) {
    return LibTreasury._getTreasuryProposalVoting(proposalId).votesNo;
  }
  function getTreasuryProposalVotingDeadlineTimestamp(uint proposalId) external view returns(uint) {
    return LibTreasury._getTreasuryProposalVoting(proposalId).deadlineTimestamp;
  }
  function isHolderVotedForProposal(uint proposalId, address holder) external view returns(bool) {
    return LibTreasury._getTreasuryProposalVoting(proposalId).voted[holder];
  }
  function isVotingForProposalStarted(uint proposalId) external view returns(bool) {
    return LibTreasury._getTreasuryProposalVoting(proposalId).votingStarted;
  }

  function isProposalThresholdReached(uint proposalId) external view returns(bool) {

  }

}
