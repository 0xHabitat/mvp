// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ITreasuryVotingPower} from "./ITreasuryVotingPower.sol";

interface ITreasury {
  enum VotingType {
    FungibleTokenVoting, // or default voting
    OneAddressOneToken // or a.k.a. multisig
  }
  // FungibleTokenVoting=0, OneAddressOneToken=1

  struct Proposal {
    bool proposalAccepted;
    address destinationAddress;
    uint256 value;
    bytes callData;
    bool proposalExecuted;
  }

  struct ProposalVoting {
    bool votingStarted;
    mapping(address => bool) voted;
    uint256 deadlineTimestamp;
    uint256 votesYes;
    uint256 votesNo;
  }

  struct Treasury {
    VotingType votingType;
    ITreasuryVotingPower.TreasuryVotingPower treasuryVotingPower; // think where better add struct
    uint128 maxDuration;
    uint128 proposalsCount;
    uint256[] activeProposalsIds;
    mapping(uint256 => Proposal) proposals;
    mapping(uint256 => ProposalVoting) proposalVotings;
  }

  function getVotingType() external view returns (VotingType);

  function getTreasuryMaxDuration() external view returns (uint128);

  function getProposalsCount() external view returns (uint128);

  function getActiveProposalsIds() external view returns (uint256[] memory);

  function getTreasuryProposal(uint256 proposalId) external view returns (Proposal memory);

  // return ProposalVoting struct
  function getTreasuryProposalVotingVotesYes(uint256 proposalId) external view returns (uint256);

  function getTreasuryProposalVotingVotesNo(uint256 proposalId) external view returns (uint256);

  function getTreasuryProposalVotingDeadlineTimestamp(uint256 proposalId)
    external
    view
    returns (uint256);

  function isHolderVotedForProposal(uint256 proposalId, address holder)
    external
    view
    returns (bool);

  function isVotingForProposalStarted(uint256 proposalId) external view returns (bool);

  function hasVotedInActiveProposals(address voter) external view returns (bool);
}
