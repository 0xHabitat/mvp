// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDecider {

  enum DecisionType {
    None,
    OnlyOwner,
    VotingPowerManagerERC20, // stake contract
    Signers // Gnosis
    //ERC20PureVoting, // Compound
    //BountyCreation - gardener, worker, reviewer - 3 signers
  }

  function isSetupComplete() external returns(bool);

  function deciderType() external returns(DecisionType);

  function directCaller() external returns(address);

  function isCallerAllowedToCreateProposal(
    address caller,
    bytes memory specificData
  ) external returns(bool allowed, string memory reason);

  function initiateDecisionProcess(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external returns(uint256 executionTimestamp);

  function decideOnProposal(
    string memory msName,
    uint256 proposalId,
    address decider,
    bool decision
  ) external;

  function isDirectCallerSetup() external returns(bool);

  function directCallerExecutionTimestamp(bytes memory specificData) external returns(uint256);

  function acceptOrRejectProposal(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external returns(bool);

  function executeProposal(
    string memory msName,
    uint256 proposalId,
    bytes4 funcSelector
  ) external returns(bool);
}
