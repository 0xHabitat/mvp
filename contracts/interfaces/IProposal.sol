// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IProposal {
  struct Proposal {
      bool proposalAccepted;
      address destinationAddress;
      uint value;
      bytes callData;
      bool proposalExecuted;
      uint executionTimestamp;
      //bytes ipfsHash;
      //address proposer;
  }
}
