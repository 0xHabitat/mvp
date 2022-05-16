// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import {IManagementSystem} from "./interfaces/dao/IManagementSystem.sol";
import {IDecisionSystem} from "./interfaces/IDecisionSystem.sol";

contract ManagementSystem is IManagementSystem {
  using Math for uint256;

  string public constant VERSION = "0.1.0";

  // keccak256(
  //     "EIP712Domain(uint256 chainId,address verifyingContract)"
  // );
  bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

  // keccak256(
  //     "HabitatTx(address to,uint256 value,bytes data,uint8 operation,uint256 txGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
  // );
  bytes32 private constant HABITAT_TX_TYPEHASH = 0xea9a950a3f2990c87607be7c3b10b226fbf619b18c7b0a15190148349a300faa;


  uint256 private taskNonce;

  IDecisionSystem public decider;

  /**
   * @dev Setup function sets initial storage of contract.
   * @param _owners List of Safe owners.
   * @param _threshold Number of required confirmations for a Safe transaction.
   */
  function setup(address[] calldata _owners, uint256 _threshold) external {

  }



  /**
   * @dev Setup function sets initial storage of contract.
   * this returns true if setup was successful. the return data can encode 
   * stuff like voting delay, voting period and quorum
   */
  function isSetupComplete() public view override  returns (bool, bytes memory) {

  }


  /**
   * @dev The nonce uniquely describes each task. it is increased when a task is finalized.
   * tasks have to finalize in series.
   */    
  function nonce() public view override returns (uint256){
    return taskNonce;
  }

  /// @dev Returns the chain id used by this contract.
  function getChainId() public view override returns (uint256) {
      uint256 id;
      // solhint-disable-next-line no-inline-assembly
      assembly {
          id := chainid()
      }
      return id;
  }

  function domainSeparator() public view override returns (bytes32) {
    return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
  }

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
  ) public view returns (bytes memory) {
    bytes32 txHash =
      keccak256(
        abi.encode(
          HABITAT_TX_TYPEHASH,
          to,
          value,
          keccak256(data),
          operation,
          txGas,
          baseGas,
          gasPrice,
          gasToken,
          refundReceiver,
          _nonce
        )
      );
    return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), txHash);
  }


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
  ) public view returns (bytes32) {
    return keccak256(encodeTaskData(to, value, data, operation, txGas, baseGas, gasPrice, gasToken, refundReceiver, _nonce));
  }

  /// @dev Transfers a token and returns if it was a success
  /// @param token Token that should be transferred
  /// @param receiver Receiver to whom the token should be transferred
  /// @param amount The amount of tokens that should be transferred
  function transferToken(
    address token,
    address receiver,
    uint256 amount
  ) internal returns (bool transferred) {
    // 0xa9059cbb - keccack("transfer(address,uint256)")
    bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // We write the return value to scratch space.
      // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
      let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
      switch returndatasize()
        case 0 {
          transferred := success
        }
        case 0x20 {
          transferred := iszero(or(iszero(success), iszero(mload(0))))
        }
        default {
          transferred := 0
        }
    }
  }

  function handlePayment(
    uint256 gasUsed,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address payable refundReceiver
  ) private returns (uint256 payment) {
    // solhint-disable-next-line avoid-tx-origin
    address payable receiver = refundReceiver == address(0) ? payable(tx.origin) : refundReceiver;
    if (gasToken == address(0)) {
      // For ETH we will only adjust the gas price to not be higher than the actual used gas price
      payment = (gasUsed + baseGas) * (gasPrice < tx.gasprice ? gasPrice : tx.gasprice);
      require(receiver.send(payment), "GS011");
    } else {
      payment = (gasUsed + baseGas) * gasPrice;
      require(transferToken(gasToken, receiver, payment), "GS012");
    }
  }

  function execute(
    address to,
    uint256 value,
    bytes memory data,
    Operation operation,
    uint256 txGas
  ) internal returns (bool success) {
    if (operation == Operation.DelegateCall) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
      }
    } else {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
      }
    }
  }

  /**
   * @dev Allows to execute a Safe transaction confirmed by required number of owners and then pays the account that submitted the transaction.
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
  ) public payable returns (bool success) {
      bytes32 txHash;
      // Use scope here to limit variable lifetime and prevent `stack too deep` errors
      {
          bytes memory txHashData =
              encodeTaskData(
                  // Transaction info
                  to,
                  value,
                  data,
                  operation,
                  txGas,
                  // Payment info
                  baseGas,
                  gasPrice,
                  gasToken,
                  refundReceiver,
                  // Signature info
                  taskNonce
              );
          // Increase nonce and execute transaction.
          taskNonce++;
          txHash = keccak256(txHashData);
          decider.checkSignatures(txHash, txHashData, signatures);
      }
      // re-add guard code here

      // We require some gas to emit the events (at least 2500) after the execution and some to perform code until the execution (500)
      // We also include the 1/64 in the check that is not send along with a call to counteract potential shortings because of EIP-150
      require(gasleft() >= ((txGas * 64) / 63).max(txGas + 2500) + 500, "GS010");
      // Use scope here to limit variable lifetime and prevent `stack too deep` errors
      {
          uint256 gasUsed = gasleft();
          // If the gasPrice is 0 we assume that nearly all available gas can be used (it is always more than safeTxGas)
          // We only substract 2500 (compared to the 3000 before) to ensure that the amount passed is still higher than safeTxGas
          success = execute(to, value, data, operation, gasPrice == 0 ? (gasleft() - 2500) : txGas);
          gasUsed = gasUsed - gasleft();
          // If no safeTxGas and no gasPrice was set (e.g. both are 0), then the internal tx is required to be successful
          // This makes it possible to use `estimateGas` without issues, as it searches for the minimum gas where the tx doesn't revert
          require(success || txGas != 0 || gasPrice != 0, "GS013");
          // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
          uint256 payment = 0;
          if (gasPrice > 0) {
              payment = handlePayment(gasUsed, baseGas, gasPrice, gasToken, refundReceiver);
          }
          if (success) emit TaskExecuted(txHash, payment);
          else emit TaskCanceled(txHash, payment);
      }
      // {
      //     if (guard != address(0)) {
      //         Guard(guard).checkAfterExecution(txHash, success);
      //     }
      // }
  }

}
