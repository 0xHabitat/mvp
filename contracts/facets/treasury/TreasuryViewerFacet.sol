// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITreasury } from "../../interfaces/treasury/ITreasury.sol";

contract TreasuryViewerFacet {

  function getTreasuryProposal(uint proposalId) external view returns(ITreasury.Proposal memory) {

  }
  // return ProposalVoting struct
  function getTreasuryProposalVotingVotesYes(uint proposalId) external view returns(uint) {

  }
  function getTreasuryProposalVotingVotesNo(uint proposalId) external view returns(uint) {

  }
  function getTreasuryProposalVotingDeadlineTimestamp(uint proposalId) external view returns(uint) {

  }
  function isHolderVotedForProposal(uint proposalId, address holder) external view returns(bool) {

  }
  function isVotingForProposalStarted(uint proposalId) external view returns(bool) {

  }

  function isProposalThresholdReached(uint proposalId) external view returns(bool) {

  }

}
