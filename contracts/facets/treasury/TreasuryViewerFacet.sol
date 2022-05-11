// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ITreasury} from "../../interfaces/treasury/ITreasury.sol";
import {LibTreasury} from "../../libraries/LibTreasury.sol";

contract TreasuryViewerFacet is ITreasury {
  function getVotingType() external view override returns (VotingType) {
    return LibTreasury.treasuryStorage().votingType;
  }

  function getTreasuryMaxDuration() external view override returns (uint128) {
    return LibTreasury.treasuryStorage().maxDuration;
  }

  function getProposalsCount() external view override returns (uint128) {
    return LibTreasury.treasuryStorage().proposalsCount;
  }

  function getActiveProposalsIds() external view override returns (uint256[] memory) {
    return LibTreasury.treasuryStorage().activeProposalsIds;
  }

  function getTreasuryProposal(uint256 proposalId)
    external
    view
    override
    returns (Proposal memory)
  {
    return LibTreasury._getTreasuryProposal(proposalId);
  }

  // return ProposalVoting struct
  function getTreasuryProposalVotingVotesYes(uint256 proposalId)
    external
    view
    override
    returns (uint256)
  {
    return LibTreasury._getTreasuryProposalVoting(proposalId).votesYes;
  }

  function getTreasuryProposalVotingVotesNo(uint256 proposalId)
    external
    view
    override
    returns (uint256)
  {
    return LibTreasury._getTreasuryProposalVoting(proposalId).votesNo;
  }

  function getTreasuryProposalVotingDeadlineTimestamp(uint256 proposalId)
    external
    view
    override
    returns (uint256)
  {
    return LibTreasury._getTreasuryProposalVoting(proposalId).deadlineTimestamp;
  }

  function isHolderVotedForProposal(uint256 proposalId, address holder)
    external
    view
    override
    returns (bool)
  {
    return LibTreasury._getTreasuryProposalVoting(proposalId).voted[holder];
  }

  function isVotingForProposalStarted(uint256 proposalId) external view override returns (bool) {
    return LibTreasury._getTreasuryProposalVoting(proposalId).votingStarted;
  }

  function hasVotedInActiveProposals(address voter) external view override returns (bool) {
    ITreasury.Treasury storage treasury = LibTreasury.treasuryStorage();

    if (treasury.activeProposalsIds.length == 0) {
      return false;
    }

    for (uint256 i = 0; i < treasury.activeProposalsIds.length; i++) {
      uint256 proposalId = treasury.activeProposalsIds[i];
      bool hasVoted = treasury.proposalVotings[proposalId].voted[voter];
      if (hasVoted) {
        return true;
      }
    }

    return false;
  }
}
