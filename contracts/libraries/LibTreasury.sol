// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { ITreasury } from "../interfaces/treasury/ITreasury.sol";
import { ITreasuryVotingPower } from "../interfaces/treasury/ITreasuryVotingPower.sol";

library LibTreasury {
    bytes32 constant TREASURY_STORAGE_POSITION = keccak256("habitat.diamond.standard.treasury.storage");
/*
    struct Treasury {
        VotingType votingType;
        TreasuryVotingPower treasuryVotingPower;
        uint128 maxDeadLine;
        uint128 proposalsCount;
        uint[] activeProposalsIds;
        mapping(uint => Proposal) proposals;
        mapping(uint => ProposalVoting) proposalVotings;
    }
*/
    function treasuryStorage() internal pure returns (ITreasury.Treasury storage ts) {
        bytes32 position = TREASURY_STORAGE_POSITION;
        assembly {
            ts.slot := position
        }
    }

    function _getTreasuryProposal(uint proposalId) internal view returns(ITreasury.Proposal storage p) {
      ITreasury.Treasury storage ts = treasuryStorage();
      p = ts.proposals[proposalId];
    }

    function _getTreasuryProposalVoting(uint proposalId) internal view returns(ITreasury.ProposalVoting storage pv) {
      ITreasury.Treasury storage ts = treasuryStorage();
      pv = ts.proposalVotings[proposalId];
    }

    function _getTreasuryVotingPower() internal view returns(ITreasuryVotingPower.TreasuryVotingPower storage treasuryVotingPower) {
      ITreasury.Treasury storage ts = treasuryStorage();
      treasuryVotingPower = ts.treasuryVotingPower;
    }

    function _getTreasuryMaxDuration() internal view returns(uint128) {
      ITreasury.Treasury storage ts = treasuryStorage();
      return ts.maxDuration;
    }

    function _getTreasuryActiveProposalsIds() internal view returns(uint[] storage) {
      ITreasury.Treasury storage ts = treasuryStorage();
      return ts.activeProposalsIds;
    }

    function _removeTreasuryPropopal(uint proposalId) internal {
      ITreasury.Proposal storage proposal = _getTreasuryProposal(proposalId);
      delete proposal.proposalAccepted;
      delete proposal.destinationAddress;
      delete proposal.value;
      delete proposal.callData;
      delete proposal.proposalExecuted;
    }

    function _removeTreasuryPropopalVoting(uint proposalId) internal {
      ITreasury.ProposalVoting storage proposalVoting = _getTreasuryProposalVoting(proposalId);
      delete proposalVoting.votingStarted;
      delete proposalVoting.deadlineTimestamp;
      delete proposalVoting.votesYes;
      delete proposalVoting.votesNo;
    }

    function _hasVotedInActiveProposals(address voter) internal view returns(bool) {
      ITreasury.Treasury storage treasury = treasuryStorage();

      if (treasury.activeProposalsIds.length == 0) {
        return false;
      }

      for (uint i = 0; i < treasury.activeProposalsIds.length; i++) {
        uint proposalId = treasury.activeProposalsIds[i];
        bool hasVoted = treasury.proposalVotings[proposalId].voted[voter];
        if (hasVoted) {
          return true;
        }
      }

      return false;
    }
}
