// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITreasuryExecution } from "../../interfaces/treasury/ITreasuryExecution.sol";
import { ITreasury } from "../../interfaces/treasury/ITreasury.sol";
import { LibTreasury } from "../../libraries/LibTreasury.sol";

contract TreasuryExecutionFacet is ITreasuryExecution {

  function executeProposal(uint proposalId) external override returns(bool result) {
    ITreasury.Proposal storage proposal = LibTreasury._getTreasuryProposal(proposalId);

    require(proposal.proposalAccepted && !proposal.proposalExecuted, "Proposal does not accepted.");
    proposal.proposalExecuted = true;

    ITreasury.ProposalVoting storage proposalVoting = LibTreasury._getTreasuryProposalVoting(proposalId);

    address destination = proposal.destinationAddress;
    uint value = proposal.value;
    bytes memory callData = proposal.callData;

    assembly {
      result := call(gas(), destination, value, add(callData, 0x20), mload(callData), 0, 0)
    }

    // return data needed?
    // also maybe depend on result delete only proposalVoting if result 0

    //remove proposal and proposal voting
    delete proposal.proposalAccepted;
    delete proposal.destinationAddress;
    delete proposal.value;
    delete proposal.callData;
    delete proposal.proposalExecuted;

    //delete proposalVoting.voted; // no idea how to delete all keys in a mapping (don't want to store them in an array)
    delete proposalVoting.votingStarted;
    delete proposalVoting.deadlineTimestamp;
    delete proposalVoting.votesYes;
    delete proposalVoting.votesNo;

    emit ProposalExecuted(proposalId, destination, value, callData);
  }

  function createSubTreasuryType0() external override {

  }

  function createSubTreasuryType1() external override {

  }

}
