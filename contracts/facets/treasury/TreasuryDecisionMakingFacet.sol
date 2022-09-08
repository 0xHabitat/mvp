// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {LibVotingPowerDecisionMaking} from "../../libraries/decisionSystem/votingPower/LibVotingPowerDecisionMaking.sol";
import {ITreasuryDecisionMaking} from "../../interfaces/treasury/ITreasuryDecisionMaking.sol";
import {IProposal} from "../../interfaces/IProposal.sol";

contract TreasuryDecisionMakingFacet is ITreasuryDecisionMaking {
  // here we can implement treasury specific functions like sendERC20To or sendGovTokTo and etc.

  function createTreasuryProposal(
    address destination,
    uint256 value,
    bytes calldata callData
  ) public override returns (uint256 proposalId) {
    if (callData.length >= 4) {
      bytes4 destSelector = bytes4(callData[0:4]);
      if (destination == address(this)) {
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
    }
    // what is treasury decision system?
    uint8 decisionType = uint8(LibManagementSystem._getDecisionType("treasury"));
    if (decisionType == uint8(2)) {
      (uint proposalID, uint votingEndTimestamp) = LibVotingPowerDecisionMaking.createVPDSProposal("treasury", destination, value, callData);
      proposalId = proposalID;
      emit TreasuryProposalCreated(proposalId, votingEndTimestamp);
    }
  }

  function decideOnTreasuryProposal(uint256 proposalId, bytes memory decision) public override {
    // what is treasury decision system?
    uint8 decisionType = uint8(LibManagementSystem._getDecisionType("treasury"));

    if (decisionType == uint8(2)) {
      (bool vote) = abi.decode(decision, (bool));
      LibVotingPowerDecisionMaking.voteForVPDSProposal("treasury", proposalId, vote);
    }
  }

  function acceptOrRejectTreasuryProposal(uint256 proposalId) public override {
    // what is treasury decision system?
    uint8 decisionType = uint8(LibManagementSystem._getDecisionType("treasury"));

    if (decisionType == uint8(2)) {
      IProposal.ReturnedProposalValues memory returnedProposalValues = LibVotingPowerDecisionMaking.acceptOrRejectVPDSProposal("treasury", proposalId);
      //(bool accepted, address destination, uint value, bytes memory callData) = LibVotingPowerDecisionMaking.acceptOrRejectVPDSProposal("treasury", proposalId);
      if (returnedProposalValues.accepted) {
        emit TreasuryProposalAccepted(proposalId, returnedProposalValues.destinationAddress, returnedProposalValues.value, returnedProposalValues.callData);
      } else {
        emit TreasuryProposalRejected(proposalId, returnedProposalValues.destinationAddress, returnedProposalValues.value, returnedProposalValues.callData);
      }
    }
  }

  function executeTreasuryProposal(uint256 proposalId) public override returns (bool result) {
    // what is treasury decision system?
    uint8 decisionType = uint8(LibManagementSystem._getDecisionType("treasury"));
    if (decisionType == uint8(2)) {
      (bool success) = LibVotingPowerDecisionMaking.executeVPDSProposalCall("treasury", proposalId);
      result = success;
      if (success) {
        emit TreasuryProposalExecutedSuccessfully(proposalId);
      } else {
        emit TreasuryProposalExecutedWithRevert(proposalId);
      }
    }
  }

  function createSeveralTreasuryProposals(
    address[] calldata destinations,
    uint256[] calldata values,
    bytes[] calldata callDatas
  ) external override returns (uint256[] memory) {
    uint256 numberOfProposals = destinations.length;
    require(
      values.length == numberOfProposals &&
        callDatas.length == numberOfProposals,
      "Different array length"
    );
    uint256[] memory proposalIds = new uint256[](numberOfProposals);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      proposalIds[i] = createTreasuryProposal(
        destinations[i],
        values[i],
        callDatas[i]
      );
    }
    return proposalIds;
  }

  function decideOnSeveralTreasuryProposals(uint256[] calldata proposalsIds, bytes[] calldata decisions)
    external
    override
  {
    require(proposalsIds.length == decisions.length, "Different array length");
    for (uint256 i = 0; i < proposalsIds.length; i++) {
      decideOnTreasuryProposal(proposalsIds[i], decisions[i]);
    }
  }

  function acceptOrRejectSeveralTreasuryProposals(uint256[] calldata proposalIds) external override {
    for (uint256 i = 0; i < proposalIds.length; i++) {
      acceptOrRejectTreasuryProposal(proposalIds[i]);
    }
  }

  function executeSeveralTreasuryProposals(uint256[] memory proposalIds) external override returns (bool[] memory results) {
    results = new bool[](proposalIds.length);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      results[i] = executeTreasuryProposal(
        proposalIds[i]
      );
    }
  }
}
