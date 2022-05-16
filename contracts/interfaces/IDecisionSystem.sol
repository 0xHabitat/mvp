// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

/**
 * @title Decision System - an abstract interface that can haldle onlyOwner, multisig,
 *   erc20, and potentially other decision making processes.
 * The interface supports decision processes that can be either completely offline, 
 * follwing this order:
 *  - next operation-nonce is read of the Management system
 *  - a decision is created including execution data + nonce and hashed
 *  - signatures are collected offchain or through approveVote() function
 *  - checkNSignatures() is invoked through
 * or partially online, following this order:
 *  - 
 * @author Johba - <extraterrestrialintelligence@gmail.com>
 */

interface IDecisionSystem {


  enum DecisionType {
    None,
    OnlyOwner,
    VotingPowerManagerERC20, //stake contract
    Signers // Gnosis
    // ERC20PureVoting // Compound
    // ElectedSignersByVPManager
    // VotingPowerManagerERC721
    // VotingPowerManagerERC1155
    // BountyCreation - gardener, worker, reviewer - 3 signers
  }

  /**
   * @dev Setup function sets initial storage of contract.
   * @param _data abstract blob of data.
   */
  function setup(bytes calldata _data) external;

  /**
   * @dev Setup function sets initial storage of contract.
   * this returns true if setup was successful. the return data can encode 
   * stuff like voting delay, voting period and quorum
   */
  function isSetupComplete()  external view returns (bool);

  /**
   * @dev Emitted when a decision is created.
   */
  event DecisionCreated(
      uint256 decisionId,
      address proposer,
      address[] targets,
      uint256[] values,
      string[] signatures,
      bytes[] calldatas,
      uint256 startBlock,
      uint256 endBlock,
      string description
  );


  /**
   * @dev Emitted when a decision is canceled.
   */
  event DecisionCanceled(bytes32 proposalHash);

  /**
   * @dev Emitted when a decision is executed.
   */
  event DecisionExecuted(bytes32 proposalHash);

  /**
   * @dev Emitted when a vote is cast.
   *
   */
  event VoteCast(address indexed voter, uint256 indexed nonce, bytes32 indexed proposalHash, bytes data);

  /**
   * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
   * {IGovernor-votingPeriod} blocks after the voting starts.
   *
   * Emits a {ProposalCreated} event.
   */
  function propose(
      address[] memory targets,
      uint256[] memory values,
      bytes[] memory calldatas,
      string memory description
  ) external returns (uint256 proposalId);

  /**
   * @dev Mapping to keep track of all vote hashes that have been approved by ALL REQUIRED voters
   */    
  function getFinalizedDecision(bytes32) external view returns (bytes memory);

  /**
   * @dev Mapping to keep track of all hashes (message or transaction) that have been approved by ANY voters
   */ 
  function getApprovedDecision(address, bytes32, uint256 blockNumber) external view returns (bytes32);

  /**
   * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
   * @param dataHash Hash of the data (could be either a message hash or transaction hash)
   * @param data That should be signed (this is passed to an external validator contract)
   * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
   */
  function checkSignatures(
      bytes32 dataHash,
      bytes memory data,
      bytes memory signatures
  ) external view returns (bool);

  /**
   * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
   * @param dataHash Hash of the data (could be either a message hash or transaction hash)
   * @param data That should be signed (this is passed to an external validator contract)
   * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
   * @param requiredSignatures Amount of required valid signatures.
   */
  function checkNSignatures(
      bytes32 dataHash,
      bytes memory data,
      bytes memory signatures,
      uint256 requiredSignatures
  ) external view returns (bool);

  /**
   * @dev Marks a decision as approved. This can be used to validate a hash that is used by a signature.
   * @param hashToApprove The hash that should be marked as approved for signatures that are verified by this contract.
   */
  function approveDecision(bytes32 hashToApprove) external;


}