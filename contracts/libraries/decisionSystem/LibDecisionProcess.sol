// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../dao/LibManagementSystem.sol";
import {LibHabitatDiamond} from "../LibHabitatDiamond.sol";
import {IProposal} from "../../interfaces/IProposal.sol";
import {IDecider} from "../../interfaces/decisionSystem/IDecider.sol";

library LibDecisionProcess {
  event ProposalCreated(string indexed msName, uint256 indexed proposalId);

  event ProposalAccepted(
    string indexed msName,
    uint256 indexed proposalId,
    address indexed destinationAddress,
    uint256 value,
    bytes callData
  );

  event ProposalRejected(
    string indexed msName,
    uint256 indexed proposalId,
    address indexed destinationAddress,
    uint256 value,
    bytes callData
  );

  event ProposalExecutedSuccessfully(string indexed msName, uint256 indexed proposalId);

  event ProposalExecutedWithRevert(string indexed msName, uint256 indexed proposalId);

  function createProposal(
    string memory msName,
    address destination,
    uint256 value,
    bytes memory callData
  ) internal returns (uint256 proposalId) {
    // what is decision system?
    IDecider decider = _getDecider(msName);

    bytes memory specificData = LibManagementSystem._getMSDecisionTypeSpecificDataMemory(msName);

    uint256 executionTimestamp;
    address directCaller = decider.directCaller();
    proposalId = LibManagementSystem._getFreeProposalId(msName);
    // who is calling (EOA or module?)
    if (msg.sender != directCaller) {
      // EOA calling
      // is EOA allowed?
      (bool allowed, string memory reason) = decider.isCallerAllowedToCreateProposal(
        msg.sender,
        specificData
      );
      if (!allowed) {
        revert(reason);
      }
      // initiate decision process
      executionTimestamp = decider.initiateDecisionProcess(msName, proposalId, specificData);
      // initiator decides positive
      decider.decideOnProposal(msName, proposalId, msg.sender, true);
    } else {
      // safe-like calling
      require(decider.isDirectCallerSetup(), "Direct caller is not setup.");
      executionTimestamp = decider.directCallerExecutionTimestamp(specificData);
    }
    // initiate proposal
    IProposal.Proposal storage proposal = LibManagementSystem._getProposal(msName, proposalId);
    proposal.destinationAddress = destination;
    proposal.value = value;
    proposal.callData = callData;
    proposal.executionTimestamp = executionTimestamp;

    emit ProposalCreated(msName, proposalId);
  }

  function decideOnProposal(string memory msName, uint256 proposalId, bool decision) internal {
    IDecider decider = _getDecider(msName);

    // who is calling (EOA or module?)
    address directCaller = decider.directCaller();

    if (msg.sender != directCaller) {
      decider.decideOnProposal(msName, proposalId, msg.sender, decision);
    } else {
      revert("direct caller decides by itself");
    }
  }

  function acceptOrRejectProposal(string memory msName, uint256 proposalId) internal {
    IDecider decider = _getDecider(msName);

    IProposal.Proposal storage proposal = LibManagementSystem._getProposal(msName, proposalId);
    require(proposal.destinationAddress != address(0), "Proposal does not exist");
    require(!proposal.proposalAccepted, "Proposal is already accepted");

    bytes memory specificData = LibManagementSystem._getMSDecisionTypeSpecificDataMemory(msName);
    address directCaller = decider.directCaller();
    LibManagementSystem._removeProposalIdFromActiveList(msName, proposalId);
    // who is calling (EOA or module?)
    if (msg.sender != directCaller) {
      bool accepted = decider.acceptOrRejectProposal(msName, proposalId, specificData);
      if (accepted) {
        proposal.proposalAccepted = true;
        LibManagementSystem._addProposalIdToAccepted(msName, proposalId);

        emit ProposalAccepted(
          msName,
          proposalId,
          proposal.destinationAddress,
          proposal.value,
          proposal.callData
        );
      } else {
        emit ProposalRejected(
          msName,
          proposalId,
          proposal.destinationAddress,
          proposal.value,
          proposal.callData
        );
        LibManagementSystem._removeProposal(msName, proposalId);
      }
    } else {
      proposal.proposalAccepted = true;
      LibManagementSystem._addProposalIdToAccepted(msName, proposalId);

      emit ProposalAccepted(
        msName,
        proposalId,
        proposal.destinationAddress,
        proposal.value,
        proposal.callData
      );
    }
  }

  function executeProposalCall(
    string memory msName,
    uint256 proposalId,
    bytes4 funcSelector
  ) internal returns (bool result) {
    // what is ms decision system?
    IDecider decider = _getDecider(msName);

    IProposal.Proposal storage proposal = LibManagementSystem._getProposal(msName, proposalId);
    require(proposal.destinationAddress != address(0), "Proposal does not exist");
    require(proposal.proposalAccepted && !proposal.proposalExecuted, "Proposal does not accepted.");
    proposal.proposalExecuted = true;
    require(
      proposal.executionTimestamp <= block.timestamp,
      "Wait until proposal delay time is expired."
    );

    address directCaller = decider.directCaller();

    // who is calling (EOA or module?)
    if (msg.sender != directCaller && msg.sender != address(decider)) {
      proposal.proposalExecuted = false;
      result = decider.executeProposal(msName, proposalId, funcSelector);
    } else if (msg.sender == directCaller || msg.sender == address(decider)) {
      address destination = proposal.destinationAddress;
      uint256 value = proposal.value;
      bytes memory callData = proposal.callData;

      assembly {
        result := call(gas(), destination, value, add(callData, 0x20), mload(callData), 0, 0)
      }
      // return data needed?
      // remove from accepted
      LibManagementSystem._removeProposalIdFromAcceptedList(msName, proposalId);
      LibManagementSystem._removeProposal(msName, proposalId);
      if (result) emit ProposalExecutedSuccessfully(msName, proposalId);
      else emit ProposalExecutedWithRevert(msName, proposalId);
    }
  }

  function executeProposalDelegateCall(
    string memory msName,
    uint256 proposalId,
    bytes4 funcSelector
  ) internal disallowChangingManagementSystems(msName) returns (bool result) {
    // what is ms decision system?
    IDecider decider = _getDecider(msName);

    IProposal.Proposal storage proposal = LibManagementSystem._getProposal(msName, proposalId);
    require(proposal.destinationAddress != address(0), "Proposal does not exist");
    require(proposal.proposalAccepted && !proposal.proposalExecuted, "Proposal is not accepted.");
    proposal.proposalExecuted = true;
    require(
      proposal.executionTimestamp <= block.timestamp,
      "Wait until proposal delay time is expired."
    );

    address directCaller = decider.directCaller();

    // who is calling (EOA or module?)
    if (msg.sender != directCaller && msg.sender != address(decider)) {
      proposal.proposalExecuted = false;
      result = decider.executeProposal(msName, proposalId, funcSelector);
    } else if (msg.sender == directCaller || msg.sender == address(decider)) {
      address destination = proposal.destinationAddress;
      bytes memory callData = proposal.callData;

      assembly {
        result := delegatecall(gas(), destination, add(callData, 0x20), mload(callData), 0, 0)
      }
      // return data needed?
      // remove from accepted
      LibManagementSystem._removeProposalIdFromAcceptedList(msName, proposalId);
      LibManagementSystem._removeProposal(msName, proposalId);
      if (result) emit ProposalExecutedSuccessfully(msName, proposalId);
      else emit ProposalExecutedWithRevert(msName, proposalId);
    }
  }

  function executeProposalCallCode(
    string memory msName,
    uint256 proposalId,
    bytes4 funcSelector
  ) internal disallowChangingManagementSystems(msName) returns (bool result) {
    // what is ms decision system?
    IDecider decider = _getDecider(msName);

    IProposal.Proposal storage proposal = LibManagementSystem._getProposal(msName, proposalId);
    require(proposal.destinationAddress != address(0), "Proposal does not exist");
    require(proposal.proposalAccepted && !proposal.proposalExecuted, "Proposal does not accepted.");
    proposal.proposalExecuted = true;
    require(
      proposal.executionTimestamp <= block.timestamp,
      "Wait until proposal delay time is expired."
    );

    address directCaller = decider.directCaller();

    // who is calling (EOA or module?)
    if (msg.sender != directCaller && msg.sender != address(decider)) {
      proposal.proposalExecuted = false;
      result = decider.executeProposal(msName, proposalId, funcSelector);
    } else if (msg.sender == directCaller || msg.sender == address(decider)) {
      address destination = proposal.destinationAddress;
      bytes memory callData = proposal.callData;

      assembly {
        result := callcode(gas(), destination, 0, add(callData, 0x20), mload(callData), 0, 0)
      }
      // return data needed?
      // remove from accepted
      LibManagementSystem._removeProposalIdFromAcceptedList(msName, proposalId);
      LibManagementSystem._removeProposal(msName, proposalId);
      if (result) emit ProposalExecutedSuccessfully(msName, proposalId);
      else emit ProposalExecutedWithRevert(msName, proposalId);
    }
  }

  function _getDecider(string memory msName) internal returns (IDecider decider) {
    uint8 decisionType = uint8(LibManagementSystem._getDecisionType(msName));
    require(decisionType != uint8(0), "No decision type.");
    address deciderAddress = LibManagementSystem._getDecider(msName);
    decider = IDecider(deciderAddress);
    require(decider.isSetupComplete(), "Decider is not setup yet.");
    require(decisionType == uint8(decider.deciderType()), "The decision type does not match.");
  }

  modifier disallowChangingManagementSystems(string memory msName) {
    bytes32 msNameHash = keccak256(abi.encodePacked(msName));
    bytes32 sACMSHash = keccak256(abi.encodePacked("moduleManager"));
    if (msNameHash == sACMSHash) {
      _;
    } else {
      bytes memory mssBefore = LibManagementSystem._getManagementSystems();
      bytes32[] memory msSlotsBefore = LibManagementSystem._getMSPositionsValues();
      address apBefore = LibHabitatDiamond.getAddressesProvider();
      _;
      bytes memory mssAfter = LibManagementSystem._getManagementSystems();
      bytes32[] memory msSlotsAfter = LibManagementSystem._getMSPositionsValues();
      address apAfter = LibHabitatDiamond.getAddressesProvider();

      require(
        mssBefore.length == mssAfter.length && keccak256(mssBefore) == keccak256(mssAfter),
        "Only moduleManager can execute this one."
      );
      require(equal(msSlotsBefore, msSlotsAfter), "Only moduleManager can execute this one.");
      require(apBefore == apAfter, "Only moduleManager can execute this one.");
    }
  }

  function equal(
    bytes32[] memory _preBytes,
    bytes32[] memory _postBytes
  ) internal pure returns (bool) {
    bool success = true;

    assembly {
      let length := mload(_preBytes)

      // if lengths don't match the arrays are not equal
      switch eq(length, mload(_postBytes))
      case 1 {
        // cb is a circuit breaker in the for loop since there's
        //  no said feature for inline assembly loops
        // cb = 1 - don't breaker
        // cb = 0 - break
        let cb := 1

        let mc := add(_preBytes, 0x20)
        let end := add(mc, length)

        for {
          let cc := add(_postBytes, 0x20)
          // the next line is the loop condition:
          // while(uint256(mc < end) + cb == 2)
        } eq(add(lt(mc, end), cb), 2) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          // if any of these checks fails then arrays are not equal
          if iszero(eq(mload(mc), mload(cc))) {
            // unsuccess:
            success := 0
            cb := 0
          }
        }
      }
      default {
        // unsuccess:
        success := 0
      }
    }

    return success;
  }
}
