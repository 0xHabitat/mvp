// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { ITreasuryVoting } from "../../interfaces/treasury/ITreasuryVoting.sol";
import { ITreasury } from "../../interfaces/treasury/ITreasury.sol";
import { LibTreasuryVotingPower } from "../../libraries/treasury/LibTreasuryVotingPower.sol";
import { LibTreasury } from "../../libraries/LibTreasury.sol";

contract TreasuryVotingFacet is ITreasuryVoting {

  function createTreasuryProposal(
    address destination,
    uint value,
    bytes calldata callData,
    uint128 deadlineTimestamp
  ) public override returns(uint) {
    // check if minimumQuorum
    require(LibTreasuryVotingPower._isQuorum(), "There is no quorum yet.");
    // threshold for creating proposals
    require(LibTreasuryVotingPower._isEnoughVotingPower(msg.sender), "Not enough voting power to create proposal.");
    if (destination == address(this)) {
      bytes4 destSelector = bytes4(callData[0:4]);
      // allow to call diamond only as ERC20 functionallity
      //(transfer(address,uint256), approve(address,uint256), increaseAllowance, decreaseAllowance)
      require(
        destSelector == 0xa9059cbb ||
        destSelector == 0x095ea7b3 ||
        destSelector == 0x39509351 ||
        destSelector == 0xa457c2d7,
        "Treasury proposals are related only to governance token."
      );
    }
    // think what else requirements can be
    // start creating proposal
    uint proposalId = _getTreasuryFreeProposalId();
    // create proposal
    ITreasury.Proposal storage proposal = LibTreasury._getTreasuryProposal(proposalId);
    proposal.destinationAddress = destination;
    proposal.value = value;
    proposal.callData = callData;

    // create proposalVoting
    ITreasury.ProposalVoting storage proposalVoting = LibTreasury._getTreasuryProposalVoting(proposalId);

    proposalVoting.votingStarted = true;

    uint128 maxDuration = LibTreasury._getTreasuryMaxDuration();
    if (deadlineTimestamp == uint128(0) || deadlineTimestamp > uint128(block.timestamp) + maxDuration) {
      proposalVoting.deadlineTimestamp = uint(maxDuration) + block.timestamp;
    } else {
      proposalVoting.deadlineTimestamp = uint(deadlineTimestamp);
    }

    // initiator votes
    proposalVoting.voted[msg.sender] = true;
    proposalVoting.votesYes += LibTreasuryVotingPower._getVoterVotingPower(msg.sender);

    emit TreasuryProposalCreated(proposalId, proposalVoting.deadlineTimestamp);

    return proposalId;
  }

  function createSeveralTreasuryProposals(
    address[] calldata destinations,
    uint[] calldata values,
    bytes[] calldata callDatas,
    uint128[] calldata deadlineTimestamps
  ) external override returns(uint[] memory) {
    uint numberOfProposals = destinations.length;
    require(values.length == numberOfProposals && callDatas.length == numberOfProposals && deadlineTimestamps.length == numberOfProposals, "Different array length");
    uint[] memory proposalIds = new uint[](numberOfProposals);
    for (uint i = 0; i < proposalIds.length; i++) {
      proposalIds[i] = createTreasuryProposal(destinations[i], values[i], callDatas[i], deadlineTimestamps[i]);
    }
    return proposalIds;
  }
  // try to minimize gas here amap
  function voteForOneTreasuryProposal(
    uint proposalId,
    bool vote
  ) public override {
    ITreasury.ProposalVoting storage proposalVoting = LibTreasury._getTreasuryProposalVoting(proposalId);
    require(proposalVoting.votingStarted, "No voting rn.");
    require(!proposalVoting.voted[msg.sender], "Already voted.");
    uint amountOfVotingPower = LibTreasuryVotingPower._getVoterVotingPower(msg.sender);
    proposalVoting.voted[msg.sender] = true;
    if (vote) {
      proposalVoting.votesYes += amountOfVotingPower;
    } else {
      proposalVoting.votesNo += amountOfVotingPower;
    }
  }

  function voteForSeveralTreasuryProposals(
    uint[] calldata proposalsIds,
    bool[] calldata votes
  ) external override {
    require(proposalsIds.length == votes.length, "Different array length");
    for (uint i = 0; i < proposalsIds.length; i++) {
      voteForOneTreasuryProposal(proposalsIds[i], votes[i]);
    }
  }

  function acceptOrRejectProposal(
    uint proposalId
  ) public override {
    ITreasury.ProposalVoting storage proposalVoting = LibTreasury._getTreasuryProposalVoting(proposalId);
    ITreasury.Proposal storage proposal = LibTreasury._getTreasuryProposal(proposalId);
    require(!proposal.proposalAccepted, "Proposal is already accepted");
    require(proposalVoting.votingStarted, "No voting.");

    if (proposalVoting.votesYes > proposalVoting.votesNo) {
      if (LibTreasuryVotingPower._isProposalThresholdReached(proposalVoting.votesYes)) {
        // accept proposal
        proposalVoting.votingStarted = false;
        proposal.proposalAccepted = true;
        emit TreasuryProposalAccepted(
          proposalId,
          proposal.destinationAddress,
          proposal.value,
          proposal.callData
        );
      } else {
        // check deadlineTimestamp
        if (proposalVoting.deadlineTimestamp <= block.timestamp) {
          // reject proposal
          delete proposalVoting.votingStarted;
          delete proposalVoting.deadlineTimestamp;
          delete proposalVoting.votesYes;
          delete proposalVoting.votesNo;
          _removeProposalIdFromActive(proposalId);
          emit TreasuryProposalRejected(
            proposalId,
            proposal.destinationAddress,
            proposal.value,
            proposal.callData
          );
          delete proposal.proposalAccepted;
          delete proposal.destinationAddress;
          delete proposal.value;
          delete proposal.callData;
          delete proposal.proposalExecuted;
        } else {
          return; // no actions still need to vote and wait deadline
        }
      }
    } else {
      if (LibTreasuryVotingPower._isProposalThresholdReached(proposalVoting.votesNo)) {
        // proposal rejected
        delete proposalVoting.votingStarted;
        delete proposalVoting.deadlineTimestamp;
        delete proposalVoting.votesYes;
        delete proposalVoting.votesNo;
        _removeProposalIdFromActive(proposalId);
        emit TreasuryProposalRejected(
          proposalId,
          proposal.destinationAddress,
          proposal.value,
          proposal.callData
        );
        delete proposal.proposalAccepted;
        delete proposal.destinationAddress;
        delete proposal.value;
        delete proposal.callData;
        delete proposal.proposalExecuted;
      } else {
        if (proposalVoting.deadlineTimestamp <= block.timestamp) {
          // proposal rejected
          delete proposalVoting.votingStarted;
          delete proposalVoting.deadlineTimestamp;
          delete proposalVoting.votesYes;
          delete proposalVoting.votesNo;
          _removeProposalIdFromActive(proposalId);
          emit TreasuryProposalRejected(
            proposalId,
            proposal.destinationAddress,
            proposal.value,
            proposal.callData
          );
          delete proposal.proposalAccepted;
          delete proposal.destinationAddress;
          delete proposal.value;
          delete proposal.callData;
          delete proposal.proposalExecuted;
        } else {
          return; // no actions still need to vote and wait deadline
        }
      }
    }
  }

  function acceptOrRejectSeveralProposals(
    uint[] calldata proposalIds
  ) external override {
    for (uint i = 0; i < proposalIds.length; i++) {
      acceptOrRejectProposal(proposalIds[i]);
    }
  }

  function _getTreasuryFreeProposalId() internal returns(uint proposalId) {
    ITreasury.Treasury storage ts = LibTreasury.treasuryStorage();
    require(ts.activeProposalsIds.length < 200, "No more proposals pls");
    ts.proposalsCount = ts.proposalsCount + uint128(1);
    proposalId = uint(ts.proposalsCount);
    ts.activeProposalsIds.push(proposalId);
  }

  function _removeProposalIdFromActive(uint proposalId) internal {
    uint[] storage activeProposalsIds = LibTreasury._getTreasuryActiveProposalsIds();
    require(activeProposalsIds.length > 0, "No active proposals.");
    if (activeProposalsIds[activeProposalsIds.length - 1] == proposalId) {
      activeProposalsIds.pop();
    } else {
      // try to find array index
      uint indexId;
      for (uint index = 0; index < activeProposalsIds.length; index++) {
        if (activeProposalsIds[index] == proposalId) {
          indexId = index;
        }
      }
      // replace last
      activeProposalsIds[indexId] = activeProposalsIds[activeProposalsIds.length - 1];
      activeProposalsIds[activeProposalsIds.length - 1] = proposalId;
      activeProposalsIds.pop();
    }
  }

}
