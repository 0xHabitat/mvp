// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

/// @title Voting System.
/// @author Johba - <extraterrestrialintelligence@gmail.com>

interface IVotingSystem {

    /// @dev Setup function sets initial storage of contract.
    /// @param _data abstract blob of data.
    function setup(bytes calldata _data) external;

    function isSetupComplete() external view returns (bool);


    /**
     * @dev The nonce uniquely describes each vote. it is increased when a vote finalizes.
     */    
    function getNonce() external view returns (uint256);

    /**
     * @dev Mapping to keep track of all vote hashes that have been approved by ALL REQUIRED voters
     */    
    function getFinalizedVote(bytes32) external view returns (bytes32);

    /**
     * @dev Mapping to keep track of all hashes (message or transaction) that have been approved by ANY voters
     */ 
    function getApprovedVotes(address, bytes32) external view returns (bytes32);

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
     * @dev Marks a vote as approved. This can be used to validate a hash that is used by a signature.
     * @param hashToApprove The hash that should be marked as approved for signatures that are verified by this contract.
     */
    function approveVote(bytes32 hashToApprove) external;

    /// @dev Returns the chain id used by this contract.
    function getChainId() external view returns (uint256);

    function domainSeparator() external view returns (bytes32);


}