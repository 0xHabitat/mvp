// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITreasuryVotingPower } from "./ITreasuryVotingPower.sol";

interface ITreasury {

    enum VotingType {
      FungibleTokenVoting, // or default voting
      OneAddressOneToken   // or a.k.a. multisig
    }
    // FungibleTokenVoting=0, OneAddressOneToken=1

    struct Proposal {
        bool proposalAccepted; // require(true) in executeProposal function
        address destinationAddress;
        uint value;
        bytes callData;
        bool proposalExecuted;
        // remove proposal at the end of the executeProposal function if accepted or at the end of acceptOrRejectProposal if rejected
    }

    struct ProposalVoting {
      bool votingStarted; // set true when createProposal and autoset to default false when struct is removed
      mapping(address => bool) voted; // main issue how to delete (don't want array)
      uint deadlineTimestamp;
      uint votesYes;
      uint votesNo;
    }

    struct Treasury {
        VotingType votingType;
        ITreasuryVotingPower.TreasuryVotingPower treasuryVotingPower; // think where better add struct
        uint128 maxDuration; // constructor parameter
        uint128 proposalsCount;
        uint[] activeProposalsIds;
        mapping(uint => Proposal) proposals;
        mapping(uint => ProposalVoting) proposalVotings; // key is removed at the end of acceptOrRejectProposal
    }

    function getTreasuryProposal(uint proposalId) external view returns(Proposal memory);
    // return ProposalVoting struct
    function getTreasuryProposalVotingVotesYes(uint proposalId) external view returns(uint);
    function getTreasuryProposalVotingVotesNo(uint proposalId) external view returns(uint);
    function getTreasuryProposalVotingDeadlineTimestamp(uint proposalId) external view returns(uint);
    function isHolderVotedForProposal(uint proposalId, address holder) external view returns(bool);
    function isVotingForProposalStarted(uint proposalId) external view returns(bool);

    function isProposalThresholdReached(uint proposalId) external view returns(bool);
}
