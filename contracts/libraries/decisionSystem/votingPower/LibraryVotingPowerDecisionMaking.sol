// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IProposal} from "../../../interfaces/IProposal.sol";
import {LibVotingPower} from "./LibVotingPower.sol";
import {LibManagementSystemVotingPower} from "./LibManagementSystemVotingPower.sol";
import {LibDAOStorage} from "../../dao/LibDAOStorage.sol";

library LibVotingPowerDecisionMaking {
  event FinalVotes(
    string indexed msName,
    uint indexed proposalId,
    uint votesYes,
    uint votesNo
  );
  // general treasury will look like:
  // createTreasuryProposal
  // decideOnTreasuryProposal
  // acceptOrRejectTreasuryProposal
  // executeTreasuryProposal
  // with internal functions on how to act depends on decisionSystem
  // each decisionSystem has its own internal functions
  function createVPDSProposal(
    string memory msName,
    address destination,
    uint256 value,
    bytes calldata callData
  ) internal returns (uint256, uint256) {
    // check if minimumQuorum
    uint64 minimumQuorumNumerator = LibManagementSystemVotingPower._getMinimumQuorumNumerator(msName);
    require(LibVotingPower._calculateIsQuorum(minimumQuorumNumerator), "There is no quorum yet.");
    // threshold for creating proposals
    uint64 thresholdForProposalNumerator = LibManagementSystemVotingPower._getThresholdForProposalNumerator(msName);
    require(
      LibVotingPower._calculateIsEnoughVotingPower(msg.sender, thresholdForProposalNumerator),
      "Not enough voting power to create proposal."
    );

    // start creating proposal
    uint256 proposalId = LibManagementSystemVotingPower._getFreeProposalId(msName);
    // create proposal
    IProposal.Proposal storage proposal = LibManagementSystemVotingPower._getProposal(msName, proposalId);
    proposal.destinationAddress = destination;
    proposal.value = value;
    proposal.callData = callData;
    uint votingEndTimestamp = uint256(LibManagementSystemVotingPower._getSecondsProposalVotingPeriod(msName)) + block.timestamp;
    proposal.executionTimestamp = uint256(LibManagementSystemVotingPower._getSecondsProposalExecutionDelayPeriod(msName)) + votingEndTimestamp;

    // create proposalVoting
    IVotingPower.ProposalVoting storage proposalVoting = LibVotingPower._getProposalVoting(
      keccak256(abi.encodePacked(msName,proposalId))
    );

    proposalVoting.votingStarted = true;
    proposalVoting.votingEndTimestamp = votingEndTimestamp;
    proposalVoting.unstakeTimestamp = proposal.executionTimestamp;

    // initiator votes
    uint initiatorVotingPower = LibVotingPower._getVoterVotingPower(msg.sender);
    LibVotingPower._setTimestampToUnstake(msg.sender, proposal.executionTimestamp);
    proposalVoting.votedAmount[msg.sender] = initiatorVotingPower; // rething this
    proposalVoting.votesYes += initiatorVotingPower;

    //emit TreasuryProposalCreated(proposalId, proposalVoting.votingEndTimestamp);

    return (proposalId, proposalVoting.votingEndTimestamp);
  }

  function voteForVPDSProposal(string memory msName, uint256 proposalId, bool vote) internal {
    IVotingPower.ProposalVoting storage proposalVoting = LibVotingPower._getProposalVoting(
      keccak256(abi.encodePacked(msName,proposalId))
    );
    require(proposalVoting.votingStarted, "No voting rn.");
    uint256 currentVotingPower = LibVotingPower._getVoterVotingPower(msg.sender);
    require(proposalVoting.votedAmount[msg.sender] < currentVotingPower, "Already voted.");
    uint difference = currentVotingPower - proposalVoting.votedAmount[msg.sender];
    LibVotingPower._setTimestampToUnstake(msg.sender, proposalVoting.unstakeTimestamp);
    proposalVoting.votedAmount[msg.sender] += difference;
    if (vote) {
      proposalVoting.votesYes += difference;
    } else {
      proposalVoting.votesNo += difference;
    }
    // remove previous votes for proposals that are already accepted or rejected
  }

  function acceptOrRejectVPDSProposal(string memory msName, uint256 proposalId) internal returns(bool accepted, uint, address, uint, bytes) {
    IVotingPower.ProposalVoting storage proposalVoting = LibVotingPower._getProposalVoting(
      keccak256(abi.encodePacked(msName,proposalId))
    );
    IProposal.Proposal storage proposal = LibManagementSystemVotingPower._getProposal(msName, proposalId);
    require(!proposal.proposalAccepted, "Proposal is already accepted");
    require(proposalVoting.votingStarted, "No voting.");
    require(proposalVoting.votingEndTimestamp <= block.timestamp, "Voting period is not ended yet.");

    uint votesYes = proposalVoting.votesYes;
    uint votesNo = proposalVoting.votesNo;
    LibManagementSystemVotingPower._removeProposalIdFromActiveVoting(msName, proposalId);
    LibVotingPower._removeProposalVoting(keccak256(abi.encodePacked(msName,proposalId)));
    uint64 thresholdForProposal = LibManagementSystemVotingPower._getThresholdForProposalNumerator(msName);
    bool proposalThresholdReachedYes = LibVotingPower._calculateIsProposalThresholdReached(votesYes, thresholdForProposal);
    bool proposalThresholdReachedNo = LibVotingPower._calculateIsProposalThresholdReached(votesNo, thresholdForProposal);
    emit FinalVotes(msName, proposalId, votesYes, votesNo);
    if (proposalThresholdReachedYes && proposalThresholdReachedNo) {
      if (votesYes > votesNo) {
        // accept proposal
        proposal.proposalAccepted = true;
        LibManagementSystemVotingPower._addProposalIdToAccepted(msName, proposalId);
        /*emit TreasuryProposalAccepted(
          proposalId,
          proposal.destinationAddress,
          proposal.value,
          proposal.callData
        );
        */
        return (true, proposalId, proposal.destinationAddress, proposal.value, proposal.callData);
      } else {
        // proposal rejected
        /*
        emit TreasuryProposalRejected(
          proposalId,
          proposal.destinationAddress,
          proposal.value,
          proposal.callData
        );
        */
        address destinationAddress = proposal.destinationAddress;
        uint value = proposal.value;
        bytes memory callData = proposal.callData;
        LibManagementSystemVotingPower._removeProposal(msName, proposalId);
        return (false, proposalId, destinationAddress, value, callData);
      }
    } else if(proposalThresholdReachedYes) {
      // accept proposal
      proposal.proposalAccepted = true;
      LibManagementSystemVotingPower._addProposalIdToAccepted(msName, proposalId);
      /*emit TreasuryProposalAccepted(
        proposalId,
        proposal.destinationAddress,
        proposal.value,
        proposal.callData
      );
      */
      return (true, proposalId, proposal.destinationAddress, proposal.value, proposal.callData);
    } else {
      // proposal rejected
      /*
      emit TreasuryProposalRejected(
        proposalId,
        proposal.destinationAddress,
        proposal.value,
        proposal.callData
      );
      */
      address destinationAddress = proposal.destinationAddress;
      uint value = proposal.value;
      bytes memory callData = proposal.callData;
      LibManagementSystemVotingPower._removePropopal(msName, proposalId);
      return (false, proposalId, destinationAddress, value, callData);
    }
  }

  function executeVPDSProposalCall(string msName, uint256 proposalId) internal returns(bool, uint256) {
    IProposal.Proposal storage proposal = LibManagementSystemVotingPower._getProposal(msName, proposalId);
    require(proposal.proposalAccepted && !proposal.proposalExecuted, "Proposal does not accepted.");
    proposal.proposalExecuted = true;
    require(proposal.executionTimestamp <= block.timestamp, "Wait until proposal delay time is expired.");

    address destination = proposal.destinationAddress;
    uint256 value = proposal.value;
    bytes memory callData = proposal.callData;
    bool result;

    assembly {
      result := call(gas(), destination, value, add(callData, 0x20), mload(callData), 0, 0)
    }
    // return data needed?
    // remove from accepted
    LibManagementSystemVotingPower._removePropopalIdFromAcceptedList(msName, proposalId);
    LibManagementSystemVotingPower._removePropopal(msName, proposalId);
    return (result, proposalId);
  }

  function executeVPDSProposalDelegateCall(string memory msName, uint256 proposalId) internal disallowChangingManagementSystems(msName) returns(bool, uint256) {
    IProposal.Proposal storage proposal = LibManagementSystemVotingPower._getProposal(msName, proposalId);
    require(proposal.proposalAccepted && !proposal.proposalExecuted, "Proposal does not accepted.");
    proposal.proposalExecuted = true;
    require(proposal.executionTimestamp <= block.timestamp, "Wait until proposal delay time is expired.");

    address destination = proposal.destinationAddress;
    bytes memory callData = proposal.callData;
    bool result;

    assembly {
      result := delegatecall(gas(), destination, add(callData, 0x20), mload(callData), 0, 0)
    }
    // return data needed?
    LibManagementSystemVotingPower._removePropopalIdFromAcceptedList(msName, proposalId);
    LibManagementSystemVotingPower._removePropopal(msName, proposalId);
    return (result, proposalId);
  }

  modifier disallowChangingManagementSystems(string memory msName) {
    bytes32 msNameHash = keccak256(abi.encodePacked(msName));
    bytes32 sACMSHash = keccak256(abi.encodePacked("setAddChangeManagementSystem"));
    if (msNameHash == sACMSHash) {
      _;
    } else {
      bytes32 msPos = LibDAOStorage._getManagementSystemsPosition();
      uint numMS;
      assembly {
        numMS := sload(msPos)
      }
      bytes storedStructBeforeFE = new bytes(numMS * 96 + 64);
      assembly {
        for {let i:=0} lt(mul(i, 0x20), numMS * 3 + 2) {i := add(i, 0x01)} {
          let storedBlock32bytes := sload(add(msPos, i))
          mstore(add(storedStruct, add(0x20, mul(i, 0x20))), storedBlock32bytes)
        }
      }
      _;
      bytes storedStructAfterFE = new bytes(numMS * 96 + 64);
      assembly {
        for {let i:=0} lt(mul(i, 0x20), numMS * 3 + 2) {i := add(i, 0x01)} {
          let storedBlock32bytes := sload(add(msPos, i))
          mstore(add(storedStruct, add(0x20, mul(i, 0x20))), storedBlock32bytes)
        }
      }
      require(storedStructBeforeFE == storedStructAfterFE, "Only setAddChangeManagementSystem can execute this one.");
    }
  }
}
