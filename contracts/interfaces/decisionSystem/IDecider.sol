// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDecider {
  enum DecisionType {
    None,
    OnlyOwner,
    VotingPowerManagerERC20,
    Signers
    // ERC20PureVoting
    // BountyCreation - gardener, worker, reviewer - 3 signers
  }

  /**
   * @notice Returns true, if decider setup is completed.
   * @return True, if setup is completed.
   */
  function isSetupComplete() external returns (bool);

  /**
   * @notice Returns decision system type.
   * @return uint8 decider type.
   */
  function deciderType() external returns (DecisionType);

  /**
   * @notice Returns the address, which is allowed to make and execute decisions directly.
   * @dev It is assumed, that direct caller could avoid the decision process stages and make them in one call.
   * @return Direct caller address.
   */
  function directCaller() external returns (address);

  /**
   * @notice Returns true, if direct caller is setup.
   * @return True, if direct caller is setup.
   */
  function isDirectCallerSetup() external returns (bool);

  /**
   * @notice Method based on specific data provided by the DAO,
   *         returns the proposal execution timestamp for direct caller.
   * @return The proposal execution timestamp for direct caller.
   */
  function directCallerExecutionTimestamp(bytes memory specificData) external returns (uint256);

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
  ) external returns (bool allowed, string memory reason);

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
  ) external returns (uint256 executionTimestamp);

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
  ) external;

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
  ) external returns (bool);

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
  ) external returns (bool);
}
