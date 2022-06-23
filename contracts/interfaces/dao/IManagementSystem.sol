// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDecisionSystem} from "../IDecisionSystem.sol";

interface IManagementSystem {

  struct ManagementSystem {
    VotingSystem governanceVotingSystem;
    VotingSystem treasuryVotingSystem;
    VotingSystem subDAOCreationVotingSystem;
    VotingSystem changeManagementSystem;
    // VotingSystem bountyCreation;
    bytes32 managementDataPosition;
  }

  struct ManagementData {
    address votingPowerManager;
    address[] governanceSigners;
    address[] treasurySigners;
    address[] subDAOCreationSigners;
    //address governanceERC20Token;
    //address[] signers; // maybe better use Gnosis data structure (nested array) instead of array
  }  

  struct VotingSystems {
    VotingSystem governanceVotingSystem;
    VotingSystem treasuryVotingSystem;
    VotingSystem subDAOCreationVotingSystem;
  }

  enum Operation {
    Call,
    DelegateCall
  }

  enum TaskState {
    Pending,
    Active,
    Canceled,
    Defeated,
    Succeeded,
    Queued,
    Expired,
    Executed
  }

  /**
   * @dev Emitted when a proposal is created.
   */
  event TaskCreated(
    uint256 taskNonce,
    address target,    // contract addresses
    uint256 value,     // amount of eth sent to contracts
    bytes cdata,
    bytes data
  );

  /**
   * @dev Emitted when a proposal is canceled.
   */
  event TaskCanceled(bytes32 taskHash, uint256 payment);

  /**
   * @dev Emitted when a proposal is executed.
   */
  event TaskExecuted(bytes32 taskHash, uint256 payment);


  /**
   * @dev Setup function sets initial storage of contract.
   * @param _decider initialized decider contract
   */
  function setup(IDecisionSystem _decider) external;

  /**
   * @dev Setup function sets initial storage of contract.
   * this returns true if setup was successful. the return data can encode 
   * stuff like voting delay, voting period and quorum and meta data.
   */
  function isSetupComplete() external view returns (bool, bytes memory);

  function getDecider() external view returns (address);

  /**
   * @dev The nonce uniquely describes each task. it is increased when a task is finalized.
   * tasks have to finalize in series.
   */    
  function nonce() external view returns (uint256);

  /**
   * @dev Returns the chain id used by this contract.
   */
  function getChainId()  external view returns (uint256);

  function domainSeparator()  external view returns (bytes32);

  function encodeTaskData(
    address to,
    uint256 value,
    bytes calldata data,
    Operation operation,
    uint256 txGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address refundReceiver,
    uint256 _nonce
  ) external view returns (bytes memory);

  /**
   * @dev Returns hash to be signed by owners.
   * @param to Destination address.
   * @param value Ether value.
   * @param data Data payload.
   * @param operation Operation type.
   * @param txGas Fas that should be used for the safe transaction.
   * @param baseGas Gas costs for data used to trigger the safe transaction.
   * @param gasPrice Maximum gas price that should be used for this transaction.
   * @param gasToken Token address (or 0 if ETH) that is used for the payment.
   * @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
   * @param _nonce Transaction nonce.
   * @return Transaction hash.
   */
  function hashTask(
      address to,
      uint256 value,
      bytes calldata data,
      Operation operation,
      uint256 txGas,
      uint256 baseGas,
      uint256 gasPrice,
      address gasToken,
      address refundReceiver,
      uint256 _nonce
  ) external view returns (bytes32);

  /**
   * @dev Allows to execute a task confirmed by decision system and then pays the account that submitted the transaction.
   *      Note: The fees are always transferred, even if the user transaction fails.
   * @param to Destination address of Safe transaction.
   * @param value Ether value of Safe transaction.
   * @param data Data payload of Safe transaction.
   * @param operation Operation type of Safe transaction.
   * @param txGas Gas that should be used for the Safe transaction.
   * @param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
   * @param gasPrice Gas price that should be used for the payment calculation.
   * @param gasToken Token address (or 0 if ETH) that is used for the payment.
   * @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
   * @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
   */
  function execTask(
      address to,
      uint256 value,
      bytes calldata data,
      Operation operation,
      uint256 txGas,
      uint256 baseGas,
      uint256 gasPrice,
      address gasToken,
      address payable refundReceiver,
      bytes memory signatures
  ) external payable returns (bool success);


}
