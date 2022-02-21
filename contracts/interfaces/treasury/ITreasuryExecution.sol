// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ITreasuryExecution {

  event ProposalExecuted(
    uint indexed proposalId,
    address indexed destination,
    uint indexed value,
    bytes callData
  );

  function executeProposal(uint proposalId) external returns(bool result);

  function createSubTreasuryType0() external;

  function createSubTreasuryType1() external;

}
