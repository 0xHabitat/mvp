// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITreasuryDecisionMaking {
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

  event TreasuryProposalExecutedSuccessfully(
    uint256 indexed proposalId
  );

  event TreasuryProposalExecutedWithRevert(
    uint256 indexed proposalId
  );

  function createTreasuryProposal(
    address destination,
    uint256 value,
    bytes calldata callData
  ) external returns (uint256);

  function createSeveralTreasuryProposals(
    address[] calldata destinations,
    uint256[] calldata values,
    bytes[] calldata callDatas
  ) external returns (uint256[] memory);

  function decideOnTreasuryProposal(uint256 proposalId, bytes memory decision) external;

  function decideOnSeveralTreasuryProposals(uint256[] calldata proposalsIds, bytes[] calldata decisions)
    external;

  function acceptOrRejectTreasuryProposal(uint256 proposalId) external;

  function acceptOrRejectSeveralTreasuryProposals(uint256[] calldata proposalIds) external;

  function executeTreasuryProposal(uint256 proposalId) external returns(bool executionResult);

  function executeSeveralTreasuryProposals(uint256[] memory proposalIds) external returns (bool[] memory executionResults);

}
