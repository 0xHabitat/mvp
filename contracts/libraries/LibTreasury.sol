// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
}
