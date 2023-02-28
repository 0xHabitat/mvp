// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITreasuryActions {
  function createTreasuryProposal(
    address destination,
    uint256 value,
    bytes memory callData
  ) external returns (uint256);

  function createSeveralTreasuryProposals(
    address[] calldata destinations,
    uint256[] calldata values,
    bytes[] calldata callDatas
  ) external returns (uint256[] memory);

  function decideOnTreasuryProposal(uint256 proposalId, bool decision) external;

  function decideOnSeveralTreasuryProposals(
    uint256[] calldata proposalsIds,
    bool[] calldata decisions
  ) external;

  function acceptOrRejectTreasuryProposal(uint256 proposalId) external;

  function acceptOrRejectSeveralTreasuryProposals(uint256[] calldata proposalIds) external;

  function executeTreasuryProposal(uint256 proposalId) external returns (bool executionResult);

  function executeSeveralTreasuryProposals(
    uint256[] memory proposalIds
  ) external returns (bool[] memory executionResults);

  function sendERC20FromTreasuryInitProposal(
    address token,
    address receiver,
    uint256 amount
  ) external returns (uint256 proposalId);

  function sendETHFromTreasuryInitProposal(
    address receiver,
    uint256 value
  ) external returns (uint256 proposalId);

  function sendERC721FromTreasuryInitProposal(
    address token,
    address receiver,
    uint256 tokenId
  ) external returns (uint256 proposalId);

  function batchedTreasuryProposalExecution(
    address destination,
    uint256 value,
    bytes memory callData
  ) external returns (bool result);

  function batchedSeveralTreasuryProposalsExecution(
    address[] calldata destinations,
    uint256[] calldata values,
    bytes[] calldata callDatas
  ) external returns (bool[] memory results);

  function sendERC20FromTreasuryBatchedExecution(
    address token,
    address receiver,
    uint256 amount
  ) external returns (bool result);

  function sendETHFromTreasuryBatchedExecution(
    address receiver,
    uint256 value
  ) external returns (bool result);

  function sendERC721FromTreasuryBatchedExecution(
    address token,
    address receiver,
    uint256 tokenId
  ) external returns (bool result);
}
