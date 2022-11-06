// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDecider} from "../../interfaces/decisionSystem/IDecider.sol";

abstract contract BaseDecider is IDecider {
  event NewDecisionProcess(
    bytes32 indexed proposalKey,
    string indexed msName,
    uint256 indexed proposalId
  );

  // state
  address public dao;
  address daoSetter;
  DecisionType public deciderType;
  mapping(bytes32 => bool) public canBeExecuted;

  modifier onlyDAO() {
    require(msg.sender == dao);
    _;
  }

  constructor(address _dao, DecisionType _deciderType, address _daoSetter) {
    dao = _dao;
    deciderType = _deciderType;
    daoSetter = _daoSetter; // or leave her msg.sender? = means that is externalsDeployer -> must deploy all diamond as well and have it's storage
    // it would work even if we just put deployFunction from daoFactory to externalsDeployer and rename it as habitatDeployer (like generalDeployer)
  }

  function setDAO(address _dao) external {
    require(dao == address(0), "DAO is set.");
    require(msg.sender == daoSetter, "No rights to set dao");
    daoSetter = address(0);
    dao = _dao;
  }

  function isSetupComplete() external virtual returns(bool);

  function directCaller() external virtual returns(address);

  function isCallerAllowedToCreateProposal(
    address caller,
    bytes memory specificData
  ) external virtual returns(bool allowed, string memory reason);

  function initiateDecisionProcess(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external virtual returns(uint256 executionTimestamp);

  function decideOnProposal(
    string memory msName,
    uint256 proposalId,
    address decider,
    bool decision
  ) external virtual;

  function isDirectCallerSetup() external virtual returns(bool);

  function directCallerExecutionTimestamp(bytes memory specificData) external virtual returns(uint256);

  function acceptOrRejectProposal(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external virtual returns(bool);

  function executeProposal(
    string memory msName,
    uint256 proposalId,
    bytes4 funcSelector
  ) external virtual returns(bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName,proposalId));
    require(canBeExecuted[proposalKey], "Decider: Proposal cannot be executed.");
    canBeExecuted[proposalKey] = false;
  }
}
