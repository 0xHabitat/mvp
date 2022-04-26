// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITreasuryExecution {
  event ProposalExecuted(
    uint256 indexed proposalId,
    address indexed destination,
    uint256 indexed value,
    bytes callData
  );

  function executeProposal(uint256 proposalId) external returns (bool result);

  //function createSubTreasuryType0() external;

  //function createSubTreasuryType1() external;
}
