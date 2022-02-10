// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasuryVoting {

  event TreasuryProposalCreated(
    uint proposalId,
    uint deadlineTimestamp
  );

  event TreasuryProposalAccepted(
    uint proposalId,
    address destination,
    uint value,
    bytes callData
  );

  event TreasuryProposalRejected(
    uint proposalId,
    address destination,
    uint value,
    bytes callData
  );

  function createTreasuryProposal(
    address destination,
    uint value,
    bytes calldata callData,
    uint128 deadlineTimestamp
  ) external returns(uint);

  function createSeveralTreasuryProposals(
    address[] calldata destinations,
    uint[] calldata values,
    bytes[] calldata callDatas,
    uint128[] calldata deadlineTimestamps
  ) external returns(uint[] memory);

  function voteForOneTreasuryProposal(
    uint proposalId,
    bool vote
  ) external;

  function voteForSeveralTreasuryProposals(
    uint[] calldata proposalsIds,
    bool[] calldata votes
  ) external;

  function acceptOrRejectProposal(
    uint proposalId
  ) external;

  function acceptOrRejectSeveralProposals(
    uint[] calldata proposalIds
  ) external;

}
