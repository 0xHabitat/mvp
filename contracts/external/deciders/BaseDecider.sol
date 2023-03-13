// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDecider} from "../../interfaces/decisionSystem/IDecider.sol";

/**
 * @title BaseDecider - Abstract contract, which any Decider contract must inherit.
 *                      Provides all functions and state, which are required from a
 *                      Decider contract to be a compatible Decision System with DAO diamond.
 * @notice Default decision process:
 *            - create a proposal
 *            - decide on a proposal
 *            - accept or reject a proposal
 *            - execute a proposal
 * @dev Each decision system is unique, so all functions should have unique implementation.
 *      It is assumed that the decision process implemented into LibDecisionProcess library
 *      could be wrapped by any decision system.
 *      IMPORTANT: each external function (except setDAO) has to has onlyDAO modifier.
 * @author @roleengineer
 */
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

  /**
   * @notice Constructor function sets: the DAO address (one time, after is a const), the decision type and dao setter address.
   * @param _dao DAO diamond address. Each decider is deployed for specific dao.
   * @param _deciderType uint8 one of the listed decision types.
   * @param _daoSetter Address that is allowed to set dao address one time, if it was not set at deployment time.
   */
  constructor(address _dao, DecisionType _deciderType, address _daoSetter) {
    dao = _dao;
    deciderType = _deciderType;
    daoSetter = _daoSetter;
    // or leave here msg.sender? = means that is externalsDeployer -> must deploy all diamond as well and have it's storage
    // it would work even if we just put deployFunction from daoFactory to externalsDeployer and rename it as habitatDeployer (like generalDeployer)
  }

  /**
   * @notice Sets the dao address, if it was not set at deployment time.
   * @param _dao DAO diamond address. Each decider is deployed for specific dao.
   */
  function setDAO(address _dao) external {
    require(dao == address(0), "DAO is set.");
    require(msg.sender == daoSetter, "No rights to set dao");
    daoSetter = address(0);
    dao = _dao;
  }

  /**
   * @notice Returns true, if decider setup is completed.
   * @return True, if setup is completed.
   */
  function isSetupComplete() external virtual returns (bool);

  /**
   * @notice Returns the address, which is allowed to make and execute decisions directly.
   * @dev It is assumed, that direct caller could avoid the decision process stages and make them in one call. 
   * @return Direct caller address.
   */
  function directCaller() external virtual returns (address);

  /**
   * @notice Returns true, if direct caller is setup.
   * @return True, if direct caller is setup.
   */
  function isDirectCallerSetup() external virtual returns (bool);

  /**
   * @notice Method based on specific data provided by the DAO,
   *         returns the proposal execution timestamp for direct caller.
   * @return The proposal execution timestamp for direct caller.
   */
  function directCallerExecutionTimestamp(
    bytes memory specificData
  ) external virtual returns (uint256);

  /**
   * @notice Method defines based on provided by the DAO specific data,
   *         if the caller is allowed to create proposals.
   * @param caller Address, which is initiating proposal creation.
   * @param specificData Encoded specific for each decider type data.
   * @return allowed True, if caller is allowed to create proposal.
   * @return reason String, explaining the reason, if caller is not allowed.
   */
  function isCallerAllowedToCreateProposal(
    address caller,
    bytes memory specificData
  ) external virtual returns (bool allowed, string memory reason);

  /**
   * @notice Method based on specific data provided by the DAO,
   *         initiates decision process (all neccessary state writes),
   *         and defines the timestamp when proposal could be executed.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param specificData Encoded specific for each decider type data.
   * @return executionTimestamp The timestamp, when proposal could be executed.
   */
  function initiateDecisionProcess(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external virtual returns (uint256 executionTimestamp);

  /**
   * @notice Method register the valid decision.
   *         Valid means: proposal exist and is not accepted or rejected;
   *         `decider` has right to decide.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param decider Address that has right to decide based on decider implementation rules.
   * @param decision True - for proposal, false - against proposal.
   */
  function decideOnProposal(
    string memory msName,
    uint256 proposalId,
    address decider,
    bool decision
  ) external virtual;

  /**
   * @notice Method based on specific data provided by the DAO,
   *         accepts or rejects the proposal.
   *         If proposal is rejected, it is removed from the dao storage.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param specificData Encoded specific for each decider type data.
   * @return True, if proposal is accepted.
   */
  function acceptOrRejectProposal(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external virtual returns (bool);

  /**
   * @notice Method executes accepted proposal. DAO accepts execution call
   *         only from decider contract or it's direct caller.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param funcSelector DAO function selector, which has to be called by decider to execute proposal.
   * @return The proposal execution result, false if during execution call revert poped up.
   */
  function executeProposal(
    string memory msName,
    uint256 proposalId,
    bytes4 funcSelector
  ) external virtual returns (bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    require(canBeExecuted[proposalKey], "Decider: Proposal cannot be executed.");
    canBeExecuted[proposalKey] = false;
  }
}
