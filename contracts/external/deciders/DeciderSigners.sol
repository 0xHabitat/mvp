// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {BaseDecider} from "./BaseDecider.sol";
import {SignerSpecificData} from "../../interfaces/decisionSystem/SpecificDataStructs.sol";

enum Operation {Call, DelegateCall}

interface IGnosisSafe {
  function isOwner(address owner) external view returns (bool);
  function getThreshold() external view returns (uint256);
}

contract DeciderSigners is BaseDecider {

  struct ProposalDecision {
    bool decisionProcessStarted;
    address[] signersDecidedToAccept;
    address[] signersDecidedToReject;
    mapping(address => bool) decided;
  }

  event Decided(
    address indexed decider,
    string indexed msName,
    uint256 indexed proposalId,
    bool decision
  );

  address public gnosisSafe;

  // Proposal voting
  // proposalKey == keccak256(string msName concat uint proposalID) => ProposalDecision
  mapping(bytes32 => ProposalDecision) proposalDecisions;

  constructor(
    address _dao,
    address _daoSetter,
    DecisionType _deciderType,
    address _gnosisSafe
  ) BaseDecider(_dao, _deciderType, _daoSetter) {
    gnosisSafe = _gnosisSafe;
  }

  // DECIDER FUNCTIONS
  function isSetupComplete() external override onlyDAO returns(bool) {
    return gnosisSafe != address(0) && dao != address(0);
  }

  function directCaller() external override onlyDAO returns(address) {
    return gnosisSafe;
  }

  function isDirectCallerSetup() external override returns(bool) {
    return gnosisSafe != address(0);
  }

  function directCallerExecutionTimestamp(bytes memory specificData) external override onlyDAO returns(uint256) {
    // we don't want governance module to be allowed to effect our DeciderSigners
    //SignerSpecificData memory ssd = abi.decode(specificData, (SignerSpecificData));
    return block.timestamp;
  }

  function isCallerAllowedToCreateProposal(
    address caller,
    bytes memory specificData
  ) external override onlyDAO returns(bool, string memory) {
    bool isSigner = IGnosisSafe(gnosisSafe).isOwner(caller);
    return (isSigner, isSigner ? "" : "Not a signer in gnosis safe");
  }

  function initiateDecisionProcess(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external override onlyDAO returns(uint256 executionTimestamp) {
    // create a decision process
    bytes32 proposalKey = keccak256(abi.encodePacked(msName,proposalId));
    ProposalDecision storage proposalDecision = _getProposalDecision(proposalKey);
    require(!proposalDecision.decisionProcessStarted, "Decision process is already started.");
    proposalDecision.decisionProcessStarted = true;
    //SignerSpecificData memory ssd = abi.decode(specificData, (SignerSpecificData));
    executionTimestamp = block.timestamp;
    emit NewDecisionProcess(proposalKey, msName, proposalId);
  }

  function decideOnProposal(
    string memory msName,
    uint256 proposalId,
    address decider,
    bool decision
  ) external override onlyDAO {
    require(IGnosisSafe(gnosisSafe).isOwner(decider), "Only gnosis signers can decide.");
    // decide
    bytes32 proposalKey = keccak256(abi.encodePacked(msName,proposalId));
    ProposalDecision storage proposalDecision = _getProposalDecision(proposalKey);
    require(proposalDecision.decisionProcessStarted, "Decision process is not started yet.");
    require(!proposalDecision.decided[decider], "Already decided.");
    proposalDecision.decided[decider] = true;
    if (decision) {
      proposalDecision.signersDecidedToAccept.push(decider);
      require(proposalDecision.signersDecidedToAccept.length < 200, "Choose offchain way to make decisions.");
    } else {
      proposalDecision.signersDecidedToReject.push(decider);
      require(proposalDecision.signersDecidedToReject.length < 200, "Choose offchain way to make decisions.");
    }
    emit Decided(decider, msName, proposalId, decision);
  }

  function acceptOrRejectProposal(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external override onlyDAO returns(bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName,proposalId));
    ProposalDecision storage proposalDecision = _getProposalDecision(proposalKey);
    require(proposalDecision.decisionProcessStarted, "Decision process is not started yet.");

    uint256 threshold = IGnosisSafe(gnosisSafe).getThreshold();
    address[] storage signersDecidedToAccept = proposalDecision.signersDecidedToAccept;
    address[] storage signersDecidedToReject = proposalDecision.signersDecidedToReject;
    uint256 maxAmountOfSigners = signersDecidedToAccept.length >= signersDecidedToReject.length ? signersDecidedToAccept.length : signersDecidedToReject.length;
    require(maxAmountOfSigners >= threshold, "Threshold is not reached yet.");
    uint256 amountSignersDecidedToAccept;
    uint256 amountSignersDecidedToReject;
    for (uint256 i = 0; i < maxAmountOfSigners; i++) {
      if (signersDecidedToAccept.length != 0) {
        address signer = signersDecidedToAccept[signersDecidedToAccept.length - 1];
        if(IGnosisSafe(gnosisSafe).isOwner(signer)) {
          amountSignersDecidedToAccept += 1;
        }
        proposalDecision.decided[signer] = false;
        signersDecidedToAccept.pop();
      }

      if (signersDecidedToReject.length != 0) {
        address signer = signersDecidedToReject[signersDecidedToReject.length - 1];
        if(IGnosisSafe(gnosisSafe).isOwner(signer)) {
          amountSignersDecidedToReject += 1;
        }
        proposalDecision.decided[signer] = false;
        signersDecidedToReject.pop();
      }
    }

    bool thresholdAcceptReached = amountSignersDecidedToAccept >= threshold;
    bool thresholdRejectReached = amountSignersDecidedToReject >= threshold;
    require(thresholdAcceptReached || thresholdRejectReached, "Threshold is not reached yet.");
    // remove decision process
    proposalDecision.decisionProcessStarted = false;

    if (thresholdAcceptReached && thresholdRejectReached) {
      if (amountSignersDecidedToAccept > amountSignersDecidedToReject) {
        // accept proposal
        canBeExecuted[proposalKey] = true;
        return true;
      }
    } else if(thresholdAcceptReached) {
      // accept proposal
      canBeExecuted[proposalKey] = true;
      return true;
    }
    // proposal rejected
    return false;
  }

  function executeProposal(
    string memory msName,
    uint256 proposalId,
    bytes4 funcSelector
  ) external override onlyDAO returns(bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName,proposalId));
    require(canBeExecuted[proposalKey], "Decider: Proposal cannot be executed.");
    canBeExecuted[proposalKey] = false;
    bytes memory daoCallData = abi.encodeWithSelector(funcSelector, proposalId);
    (bool success, bytes memory returnedData) = dao.call(daoCallData);
    require(success);
    (bool returnedResult) = abi.decode(returnedData, (bool));
    return returnedResult;
  }

  // INTERNAL FUNCTIONS
  function _getProposalDecision(bytes32 proposalKey) internal returns(ProposalDecision storage pD) {
    pD = proposalDecisions[proposalKey];
  }

  // pure function
  function computeProposalKey(string memory msName, uint256 proposalId) external pure returns(bytes32) {
    return keccak256(abi.encodePacked(msName,proposalId));
  }

  // View functions
  function isDecisionProcessStarted(bytes32 proposalKey) external view returns(bool) {
    ProposalDecision storage pD = proposalDecisions[proposalKey];
    return pD.decisionProcessStarted;
  }

  function isSignerDecided(bytes32 proposalKey, address signer) external view returns(bool) {
    ProposalDecision storage pD = proposalDecisions[proposalKey];
    return pD.decided[signer];
  }

  function signersDecidedToAccept(bytes32 proposalKey) external view returns(address[] memory) {
    ProposalDecision storage pD = proposalDecisions[proposalKey];
    return pD.signersDecidedToAccept;
  }

  function signersDecidedToReject(bytes32 proposalKey) external view returns(address[] memory) {
    ProposalDecision storage pD = proposalDecisions[proposalKey];
    return pD.signersDecidedToReject;
  }

}
