// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ITreasuryVotingPower} from "./ITreasuryVotingPower.sol";

interface ITreasury {

    enum VotingType {
      FungibleTokenVoting, // or default voting
      OneAddressOneToken   // or a.k.a. multisig
    }
    // FungibleTokenVoting=0, OneAddressOneToken=1

    struct Proposal {
        bool proposalAccepted;
        address destinationAddress;
        uint value;
        bytes callData;
        bool proposalExecuted;
        uint delayDeadline;
    }

    struct ProposalVoting {
      bool votingStarted;
      mapping(address => bool) voted;
      uint deadlineTimestamp;
      uint votesYes;
      uint votesNo;
    }

    struct Treasury {
        VotingType votingType;
        ITreasuryVotingPower.TreasuryVotingPower treasuryVotingPower; // think where better add struct
        uint128 maxDuration;
        uint128 proposalsCount;
        uint256 proposalDelayTime;
        uint[] activeProposalsIds;
        mapping(uint => Proposal) proposals;
        mapping(uint => ProposalVoting) proposalVotings;
    }

    function getVotingType() external view returns(VotingType);

    function getTreasuryMaxDuration() external view returns(uint128);

    function getProposalsCount() external view returns(uint128);

    function getActiveProposalsIds() external view returns(uint[] memory);

    function getTreasuryProposal(uint proposalId) external view returns(Proposal memory);
    // return ProposalVoting struct
    function getTreasuryProposalVotingVotesYes(uint proposalId) external view returns(uint);
    function getTreasuryProposalVotingVotesNo(uint proposalId) external view returns(uint);
    function getTreasuryProposalVotingDeadlineTimestamp(uint proposalId) external view returns(uint);
    function isHolderVotedForProposal(uint proposalId, address holder) external view returns(bool);
    function isVotingForProposalStarted(uint proposalId) external view returns(bool);

    function hasVotedInActiveProposals(address voter) external view returns(bool);

}
