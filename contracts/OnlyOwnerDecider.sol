// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import {IDecisionSystem} from "./interfaces/IDecisionSystem.sol";

contract OnlyOwnerDecider is IDecisionSystem {
  using Math for uint256;

  event ApproveHash(bytes32 indexed approvedHash, address indexed owner);

  address internal constant SENTINEL_OWNERS = address(0x1);

  address private owner;
  uint256 private threshold;

  // Mapping to keep track of all hashes (message or transaction) that have been approved by ANY owners
  mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

  /**
   * @dev Setup function sets initial storage of contract.
   * @param _data abstract blob of data.
   */
  function setup(bytes calldata _data) external {
    address addr = abi.decode(_data, (address[]))[0];
    // address addr;
    // assembly {
    //   calldatacopy(addr,_data.offset,20)
    // } 
    require (addr != address(0x0), 'error');
    owner = addr;
  }

  /**
   * @dev Setup function sets initial storage of contract.
   * this returns true if setup was successful. the return data can encode 
   * stuff like voting delay, voting period and quorum
   */
  function isSetupComplete()  external view returns (bool){
    return (owner != address(0x0));
  }

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
  ) external returns (uint256 proposalId) {
    revert("not implemented");
  }

  /**
   * @dev Mapping to keep track of all vote hashes that have been approved by ALL REQUIRED voters
   */    
  function getFinalizedDecision(bytes32) external view returns (bytes memory) {
    revert("not implemented");
  }
  /**
   * @dev Mapping to keep track of all hashes (message or transaction) that have been approved by ANY voters
   */ 
  function getApprovedDecision(address, bytes32, uint256 blockNumber) external view returns (bytes32) {
    revert("not implemented");
  }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

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
  ) public view returns (bool) {
    // Check that the provided signature data is not too short
    require(signatures.length >= requiredSignatures * 65, "GS020");
    // There cannot be an owner with address 0.
    address lastOwner = address(0);
    address currentOwner;
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 i;
    for (i = 0; i < requiredSignatures; i++) {
      (v, r, s) = signatureSplit(signatures, i);
      if (v == 0) {
        // If v is 0 then it is a contract signature
        // When handling contract signatures the address of the contract is encoded into r
        currentOwner = address(uint160(uint256(r)));

        // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
        // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
        // Here we only check that the pointer is not pointing inside the part that is being processed
        require(uint256(s) >= requiredSignatures * 65, "GS021");

        // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
        require(uint256(s) + 32 <= signatures.length, "GS022");

        // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
        uint256 contractSignatureLen;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSignatureLen := mload(add(add(signatures, s), 0x20))
        }
        require(uint256(s) + 32 + contractSignatureLen <= signatures.length, "GS023");

        // Check signature
        bytes memory contractSignature;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
            contractSignature := add(add(signatures, s), 0x20)
        }
        // TODO: fix contract signatures
        // require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "GS024");
      } else if (v == 1) {
        // If v is 1 then it is an approved hash
        // When handling approved hashes the address of the approver is encoded into r
        currentOwner = address(uint160(uint256(r)));
        // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
        require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "GS025");
      } else if (v > 30) {
        // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
        // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
        currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
      } else {
        // Default is the ecrecover flow with the provided data hash
        // Use ecrecover with the messageHash for EOA signatures
        currentOwner = ecrecover(dataHash, v, r, s);
      }
      require(currentOwner > lastOwner && owner == currentOwner && currentOwner != SENTINEL_OWNERS, "GS026");
      lastOwner = currentOwner;
    }
  }


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
  ) external view returns (bool) {
    // Load threshold to avoid multiple storage loads
    uint256 _threshold = threshold;
    // Check that a threshold is set
    require(_threshold > 0, "GS001");
    checkNSignatures(dataHash, data, signatures, _threshold);
  }


  /**
   * @dev Marks a decision as approved. This can be used to validate a hash that is used by a signature.
   * @param hashToApprove The hash that should be marked as approved for signatures that are verified by this contract.
   */
  function approveDecision(bytes32 hashToApprove) external {
    require(owner == msg.sender, "GS030");
    approvedHashes[msg.sender][hashToApprove] = 1;
    emit ApproveHash(hashToApprove, msg.sender);
  }

}
