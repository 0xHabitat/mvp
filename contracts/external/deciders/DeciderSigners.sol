// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {BaseDecider} from "./BaseDecider.sol";
import {SignerSpecificData} from "../../interfaces/decisionSystem/SpecificDataStructs.sol";

enum Operation {
  Call,
  DelegateCall
}

interface IGnosisSafe {
  function isOwner(address owner) external view returns (bool);

  function getThreshold() external view returns (uint256);
}

/**
 * @title DeciderSigners - Base part of Signers Decision System - onchain/offchain decision making.
 * @notice Inherits BaseDecider and implements its function by overridding in the conve of signers decision system.
 *         Contract relies on Gnosis Safe contract to define accounts,
 *         which have right to decide, and threshold to make onchain decisions.
 *         Gnosis Safe contract is also a direct caller, which opens the door for offchain decision process by using Gnosis infrastructure.
 *         Contract accounts proposal onchain decision process on behalf of the DAO.
 * @dev Interactions flow - onchain decision process:
 *      - Signers (list of addresses that control the Safe) are interacting with
 *        the DAO contract.
 *      - Creation proposals related to DAO Modules, which current decision type is
 *        Signers, makes DAO call this contract and ask if account is able to
 *        create proposal (is gnosis owner) and if yes ask to create decision process and account to decide.
 *      - Same applies for the whole decision process (proposal create,
 *        decide on, accept or reject, execute): signers interacts with a DAO,
 *        DAO interacts with this contract, this contract based on its state and data
 *        received from the DAO conducts the decision process by its own logic.
 *      Interactions flow - offchain decision process:
 *      - Signer using gnosis interface initiate new transaction calling the DAO
 *        contract function, which name is ended by "BatchedExecution".
 *      - Signers confirm the transaction and execute it.
 * @author @roleengineer
 */
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

  /*//////////////////////////////////////////////////////////////
                    DAO INTERACTION FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns true, if gnosis and dao contracts are set.
   * @return True, if setup is completed.
   */
  function isSetupComplete() external override onlyDAO returns (bool) {
    return gnosisSafe != address(0) && dao != address(0);
  }

  /**
   * @notice Returns gnosis safe address.
   * @return gnosis safe address.
   */
  function directCaller() external override onlyDAO returns (address) {
    return gnosisSafe;
  }

  /**
   * @notice Returns true, if gnosis safe is setup.
   * @return True, if gnosis safe is setup.
   */
  function isDirectCallerSetup() external override returns (bool) {
    return gnosisSafe != address(0);
  }

  /**
   * @notice Returns proposal execution timestamp based on signers specific
   *         data provided by the DAO.
   * @dev Currently we don't want the DAO governance module to be allowed to effect
   *      our DeciderSigners, because we want immediately offchain execution for our
   *      module manager proposals.
   * @param specificData Signers specific data struct contains 1 uint256: secondsProposalExecutionDelayPeriod.
   * @return proposal execution timestamp.
   */
  function directCallerExecutionTimestamp(
    bytes memory specificData
  ) external override onlyDAO returns (uint256) {
    //SignerSpecificData memory ssd = abi.decode(specificData, (SignerSpecificData));
    return block.timestamp;
  }

  /**
   * @notice Method defines, if the `caller` is allowed to create proposal
   *         (`caller` is gnosis safe owner).
   * @param caller Address, which is initiating proposal creation.
   * @param specificData Not used.
   * @return True, if caller is allowed to create proposal.
   * @return String, explaining the reason, if caller is not allowed.
   */
  function isCallerAllowedToCreateProposal(
    address caller,
    bytes memory specificData
  ) external override onlyDAO returns (bool, string memory) {
    bool isSigner = IGnosisSafe(gnosisSafe).isOwner(caller);
    return (isSigner, isSigner ? "" : "Not a signer in gnosis safe");
  }

  /**
   * @notice Method initiates proposal onchain decision process.
   * @dev Each proposal is unique, we store it in a mapping by the key, which is
   *      calculating by keccak256 function taking module name and proposal id.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param specificData Not used.
   * @return executionTimestamp The timestamp, when proposal could be executed is returned to the DAO.
   */
  function initiateDecisionProcess(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external override onlyDAO returns (uint256 executionTimestamp) {
    // create a decision process
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalDecision storage proposalDecision = _getProposalDecision(proposalKey);
    require(!proposalDecision.decisionProcessStarted, "Decision process is already started.");
    proposalDecision.decisionProcessStarted = true;
    //SignerSpecificData memory ssd = abi.decode(specificData, (SignerSpecificData));
    executionTimestamp = block.timestamp;
    emit NewDecisionProcess(proposalKey, msName, proposalId);
  }

  /**
   * @notice Method register signer valid decision to accept or reject proposal.
   *         Valid means: decision process is started and signer has not decided yet.
   *         `decider` is gnosis safe owner.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param decider Address that is making decision.
   * @param decision True - confirm proposal, false - reject proposal.
   */
  function decideOnProposal(
    string memory msName,
    uint256 proposalId,
    address decider,
    bool decision
  ) external override onlyDAO {
    require(IGnosisSafe(gnosisSafe).isOwner(decider), "Only gnosis signers can decide.");
    // decide
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalDecision storage proposalDecision = _getProposalDecision(proposalKey);
    require(proposalDecision.decisionProcessStarted, "Decision process is not started yet.");
    require(!proposalDecision.decided[decider], "Already decided.");
    proposalDecision.decided[decider] = true;
    if (decision) {
      proposalDecision.signersDecidedToAccept.push(decider);
      require(
        proposalDecision.signersDecidedToAccept.length < 200,
        "Choose offchain way to make decisions."
      );
    } else {
      proposalDecision.signersDecidedToReject.push(decider);
      require(
        proposalDecision.signersDecidedToReject.length < 200,
        "Choose offchain way to make decisions."
      );
    }
    emit Decided(decider, msName, proposalId, decision);
  }

  /**
   * @notice Method accepts or rejects the proposal, after gnosis threshold is reached,
   *         by analizing the decisions.
   *         Sets true in canBeExecuted mapping for accepted proposal (additional security for the DAO contract).
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param specificData Not used.
   * @return True, if proposal is accepted, is returned to the DAO contract.
   */
  function acceptOrRejectProposal(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external override onlyDAO returns (bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalDecision storage proposalDecision = _getProposalDecision(proposalKey);
    require(proposalDecision.decisionProcessStarted, "Decision process is not started yet.");

    uint256 threshold = IGnosisSafe(gnosisSafe).getThreshold();
    address[] storage signersDecidedToAccept = proposalDecision.signersDecidedToAccept;
    address[] storage signersDecidedToReject = proposalDecision.signersDecidedToReject;
    uint256 maxAmountOfSigners = signersDecidedToAccept.length >= signersDecidedToReject.length
      ? signersDecidedToAccept.length
      : signersDecidedToReject.length;
    require(maxAmountOfSigners >= threshold, "Threshold is not reached yet.");
    uint256 amountSignersDecidedToAccept;
    uint256 amountSignersDecidedToReject;
    for (uint256 i = 0; i < maxAmountOfSigners; i++) {
      if (signersDecidedToAccept.length != 0) {
        address signer = signersDecidedToAccept[signersDecidedToAccept.length - 1];
        if (IGnosisSafe(gnosisSafe).isOwner(signer)) {
          amountSignersDecidedToAccept += 1;
        }
        proposalDecision.decided[signer] = false;
        signersDecidedToAccept.pop();
      }

      if (signersDecidedToReject.length != 0) {
        address signer = signersDecidedToReject[signersDecidedToReject.length - 1];
        if (IGnosisSafe(gnosisSafe).isOwner(signer)) {
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
    } else if (thresholdAcceptReached) {
      // accept proposal
      canBeExecuted[proposalKey] = true;
      return true;
    }
    // proposal rejected
    return false;
  }

  /**
   * @notice Method executes accepted proposal as DAO accepts execution call only from
   *         decider contracts or direct caller. Checks if proposal canBeExecuted.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param funcSelector DAO function selector, which has to be called by decider to execute proposal.
   * @return The proposal execution result, false if during execution call revert poped up.
   */
  function executeProposal(
    string memory msName,
    uint256 proposalId,
    bytes4 funcSelector
  ) external override onlyDAO returns (bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    require(canBeExecuted[proposalKey], "Decider: Proposal cannot be executed.");
    canBeExecuted[proposalKey] = false;
    bytes memory daoCallData = abi.encodeWithSelector(funcSelector, proposalId);
    (bool success, bytes memory returnedData) = dao.call(daoCallData);
    require(success);
    bool returnedResult = abi.decode(returnedData, (bool));
    return returnedResult;
  }

  /*//////////////////////////////////////////////////////////////
                      INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @dev Internal method that returns ProposalDecision struct.
   */
  function _getProposalDecision(
    bytes32 proposalKey
  ) internal returns (ProposalDecision storage pD) {
    pD = proposalDecisions[proposalKey];
  }

  /*//////////////////////////////////////////////////////////////
                      PURE FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns computed proposal key.
   */
  function computeProposalKey(
    string memory msName,
    uint256 proposalId
  ) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(msName, proposalId));
  }

  /*//////////////////////////////////////////////////////////////
                      VIEW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns true, if onchain decision process on proposal is started.
   */
  function isDecisionProcessStarted(bytes32 proposalKey) external view returns (bool) {
    ProposalDecision storage pD = proposalDecisions[proposalKey];
    return pD.decisionProcessStarted;
  }

  /**
   * @notice Returns true, if `signer` decided on proposal.
   */
  function isSignerDecided(bytes32 proposalKey, address signer) external view returns (bool) {
    ProposalDecision storage pD = proposalDecisions[proposalKey];
    return pD.decided[signer];
  }

  /**
   * @notice Returns an array of signers, who decided to accept proposal.
   */
  function signersDecidedToAccept(bytes32 proposalKey) external view returns (address[] memory) {
    ProposalDecision storage pD = proposalDecisions[proposalKey];
    return pD.signersDecidedToAccept;
  }

  /**
   * @notice Returns an array of signers, who decided to reject proposal.
   */
  function signersDecidedToReject(bytes32 proposalKey) external view returns (address[] memory) {
    ProposalDecision storage pD = proposalDecisions[proposalKey];
    return pD.signersDecidedToReject;
  }
}
