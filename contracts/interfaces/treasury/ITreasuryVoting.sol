// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITreasuryVoting {
  event TreasuryProposalCreated(uint256 indexed proposalId, uint256 indexed deadlineTimestamp);

  event TreasuryProposalAccepted(
    uint256 indexed proposalId,
    address indexed destination,
    uint256 indexed value,
    bytes callData
  );

  event TreasuryProposalRejected(
    uint256 indexed proposalId,
    address indexed destination,
    uint256 indexed value,
    bytes callData
  );

  function createTreasuryProposal(
    address destination,
    uint256 value,
    bytes calldata callData,
    uint128 deadlineTimestamp
  ) external returns (uint256);

  function createSeveralTreasuryProposals(
    address[] calldata destinations,
    uint256[] calldata values,
    bytes[] calldata callDatas,
    uint128[] calldata deadlineTimestamps
  ) external returns (uint256[] memory);

  function voteForOneTreasuryProposal(uint256 proposalId, bool vote) external;

  function voteForSeveralTreasuryProposals(uint256[] calldata proposalsIds, bool[] calldata votes)
    external;

  function acceptOrRejectProposal(uint256 proposalId) external;

  function acceptOrRejectSeveralProposals(uint256[] calldata proposalIds) external;
}
