// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {BaseDecider} from "./BaseDecider.sol";
import {IVotingPower} from "../../interfaces/decisionSystem/IVotingPower.sol";
import {VotingPowerSpecificData} from "../../interfaces/decisionSystem/SpecificDataStructs.sol";

interface IERC20 {
  function totalSupply() external view returns(uint256);
}

interface IVotingPowerManager {
  function governanceToken() external view returns(address);
}

contract DeciderVotingPower is BaseDecider, IVotingPower {

  struct Delegation {
    address delegatee;
    uint256 delegatedVotingPower;
    uint256 freezedAmount;
    uint256 unfreezeTimestamp;
  }

  struct ProposalVoting {
    bool votingStarted;
    mapping(address => uint) votedAmount; // rethink
    uint votingEndTimestamp;
    uint unstakeTimestamp;
    uint votesYes;
    uint votesNo;
  }

  event NewVoting(
    bytes32 indexed proposalKey,
    uint256 votingEndTimestamp
  );

  event Voted(
    address indexed voter,
    string indexed msName,
    uint256 indexed proposalId,
    bool vote
  );

  event FinalVotes(
    string indexed msName,
    uint indexed proposalId,
    uint votesYes,
    uint votesNo
  );

  // decider specific state
  address votingPowerManager;
  uint256 maxAmountOfVotingPower;
  uint256 totalAmountOfVotingPower;
  uint256 precision;
  mapping(address => uint256) votingPower;
  mapping(address => uint256) timeStampToUnstake;
  mapping(address => Delegation) delegations;

  // Proposal voting
  // proposalVotingKey == keccak256(string msName concat uint proposalID) => ProposalVoting
  mapping(bytes32 => ProposalVoting) proposalsVoting;

  constructor(
    address _dao,
    address _daoSetter,
    DecisionType _deciderType,
    address _votingPowerManager,
    uint256 _precision
  ) BaseDecider(_dao, _deciderType, _daoSetter) {
    precision = _precision;
    votingPowerManager = _votingPowerManager;
    address governanceToken = IVotingPowerManager(votingPowerManager).governanceToken();
    maxAmountOfVotingPower = IERC20(governanceToken).totalSupply();
  }

  // DAO INTERACTION FUNCTIONS

  function isSetupComplete() override external onlyDAO returns(bool) {
    // maybe here we need more complex logic?
    return votingPowerManager != address(0) && dao != address(0) && maxAmountOfVotingPower != uint256(0);
  }

  function directCaller() override external onlyDAO returns(address) {
    return address(0);
  }

  function isDirectCallerSetup() override onlyDAO external returns(bool) {
    return false;
  }

  function directCallerExecutionTimestamp(bytes memory specificData) external override onlyDAO returns(uint256) {
    revert("direct caller is not a part of voting power decision system, how do you call from address(0)?");
  }

  function isCallerAllowedToCreateProposal(
    address caller,
    bytes memory specificData
  ) external override onlyDAO returns(bool, string memory) {
    VotingPowerSpecificData memory vpsd = abi.decode(specificData, (VotingPowerSpecificData));
    bool allowed = _calculateIsEnoughVotingPower(caller, vpsd.thresholdForInitiator);
    return allowed ? (allowed, "") : (allowed, "Not enough voting power to create proposal.");
  }

  function initiateDecisionProcess(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external override onlyDAO returns(uint256 executionTimestamp) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName,proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);

    VotingPowerSpecificData memory vpsd = abi.decode(specificData, (VotingPowerSpecificData));

    proposalVoting.votingStarted = true;

    proposalVoting.votingEndTimestamp = vpsd.secondsProposalVotingPeriod + block.timestamp;
    executionTimestamp = vpsd.secondsProposalExecutionDelayPeriod + proposalVoting.votingEndTimestamp;

    proposalVoting.unstakeTimestamp = executionTimestamp;
    emit NewDecisionProcess(proposalKey, msName, proposalId);
    emit NewVoting(proposalKey, proposalVoting.votingEndTimestamp);
  }

  function decideOnProposal(
    string memory msName,
    uint256 proposalId,
    address decider,
    bool decision
  ) external override onlyDAO {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName,proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    require(proposalVoting.votingStarted, "No voting rn.");
    require(proposalVoting.votingEndTimestamp >= block.timestamp, "Voting period is ended.");
    uint deciderVotingPower = getVoterVotingPower(decider);
    require(proposalVoting.votedAmount[decider] < deciderVotingPower, "Already voted.");
    _setTimestampToUnstake(decider, proposalVoting.unstakeTimestamp);
    uint difference = deciderVotingPower - proposalVoting.votedAmount[decider];

    proposalVoting.votedAmount[decider] = deciderVotingPower; // rething this
    if (decision) {
      proposalVoting.votesYes += difference;
    } else {
      proposalVoting.votesNo += difference;
    }
    emit Voted(decider, msName, proposalId, decision);
  }
  // Must be called right after the proposal voting period deadline is expired
  // Otherwise can be manipulated (e.g. governance effects proposal threshold)
  // Best to have service that will call immediately
  function acceptOrRejectProposal(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external override onlyDAO returns(bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName,proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    require(proposalVoting.votingStarted, "No voting.");
    require(proposalVoting.votingEndTimestamp <= block.timestamp, "Voting period is not ended yet.");
    VotingPowerSpecificData memory vpsd = abi.decode(specificData, (VotingPowerSpecificData));

    uint votesYes = proposalVoting.votesYes;
    uint votesNo = proposalVoting.votesNo;
    _removeProposalVoting(proposalKey);
    uint256 thresholdForProposal = vpsd.thresholdForProposal;
    bool proposalThresholdReachedYes = _calculateIsProposalThresholdReached(votesYes, thresholdForProposal);
    bool proposalThresholdReachedNo = _calculateIsProposalThresholdReached(votesNo, thresholdForProposal);
    emit FinalVotes(msName, proposalId, votesYes, votesNo);
    if (proposalThresholdReachedYes && proposalThresholdReachedNo) {
      if (votesYes > votesNo) {
        // accept proposal
        canBeExecuted[proposalKey] = true;
        return true;
      }
    } else if(proposalThresholdReachedYes) {
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

  // DECIDER FUNCTIONS

  // increasing voting power
  function increaseVotingPower(address voter, uint256 amount) external {
    require(msg.sender == votingPowerManager);
    // increase totalVotingPower
    totalAmountOfVotingPower += amount;
    // increase voter voting power
    votingPower[voter] += amount;
  }

  // decreasing voting power
  function decreaseVotingPower(address voter, uint256 amount) external {
    require(msg.sender == votingPowerManager);
    require(
      timeStampToUnstake[voter] <= block.timestamp,
      "Cannot unstake now."
    );
    // decrease totalVotingPower
    totalAmountOfVotingPower -= amount;
    // decrease voter voting power
    votingPower[voter] -= amount;
  }

  function delegateVotingPower(address delegatee) external {
    require(timeStampToUnstake[msg.sender] < block.timestamp, "Wait timestamp to delegate");
    uint256 amountOfVotingPower = votingPower[msg.sender];
    require(amountOfVotingPower > 0, "Nothing to delegate");

    Delegation storage delegation = delegations[msg.sender];

    require(delegation.delegatee == delegatee || delegation.delegatee == address(0), "Undelegate before delegate to another delegatee.");
    // set delegatee of delegator
    delegation.delegatee = delegatee;
    // set to zero delegator voting power
    votingPower[msg.sender] = uint256(0);
    // set how much voting power was delegated to delegatee from delegator
    delegation.delegatedVotingPower += amountOfVotingPower;
    // increase delegatee voting power
    votingPower[delegatee] += amountOfVotingPower;
  }

  function undelegateVotingPower() external {
    Delegation storage delegation = delegations[msg.sender];
    require(delegation.delegatee != address(0), "Have not delegate yet.");
    require(delegation.delegatedVotingPower > 0, "Nothing to undelegate.");
    // remove delegetee
    address delegatee = delegation.delegatee;
    delegation.delegatee = address(0);
    // set timeStampToUnstake at least same as delegatee has
    uint delegateeTimeStampToUnstake = timeStampToUnstake[delegatee];
    if (timeStampToUnstake[msg.sender] < delegateeTimeStampToUnstake) {
      timeStampToUnstake[msg.sender] = delegateeTimeStampToUnstake;
    }

    uint256 amountOfDelegatedVotingPower = delegation.delegatedVotingPower;
    // set to zero delegatedVotingPower
    delegation.delegatedVotingPower = uint256(0);
    // take voting power back from delegatee
    votingPower[delegatee] -= amountOfDelegatedVotingPower;
    if (delegateeTimeStampToUnstake < block.timestamp) {
      // give voting power back to delegator
      votingPower[msg.sender] += amountOfDelegatedVotingPower;
    } else {
      // freeze votingPower with timestamp to unfreeze
      delegation.unfreezeTimestamp = delegateeTimeStampToUnstake;
      delegation.freezedAmount += amountOfDelegatedVotingPower;
    }
  }

  function unfreezeVotingPower() external {
    Delegation storage delegation = delegations[msg.sender];

    require(delegation.unfreezeTimestamp < block.timestamp, "Wait timestamp to unfreeze");
    uint amountOfVotingPower = delegation.freezedAmount;
    delegation.freezedAmount = 0;
    votingPower[msg.sender] += amountOfVotingPower;
  }

  // INTERNAL FUNCTIONS
  function _setTimestampToUnstake(address staker, uint256 timestamp) internal {
    if (timeStampToUnstake[staker] < timestamp) {
      timeStampToUnstake[staker] = timestamp;
    }
  }

  function _getProposalVoting(bytes32 proposalKey) internal view returns(ProposalVoting storage pV) {
    pV = proposalsVoting[proposalKey];
  }
  // rethink if remove as well
  // Now i think that we will not remove voting,
  // because we want the source of results as we don't use a server and parsing
  // blockchain logs
  // we just put votingStarted false (looks enough to protect doublespending)
  function _removeProposalVoting(bytes32 proposalKey) internal {
    ProposalVoting storage pV = _getProposalVoting(proposalKey);
    delete pV.votingStarted;
    delete pV.votingEndTimestamp;
    delete pV.unstakeTimestamp;
    delete pV.votesYes;
    delete pV.votesNo;
    // rethink votedAmount
  }

  function _calculateIsEnoughVotingPower(address holder, uint256 thresholdForInitiator) internal view returns (bool) {
    if (totalAmountOfVotingPower < maxAmountOfVotingPower) {
      return
        votingPower[holder] >=
        ((thresholdForInitiator * maxAmountOfVotingPower) / precision);
    } else {
      return
        votingPower[holder] >=
        ((thresholdForInitiator * totalAmountOfVotingPower) / precision);
    }
  }

  function _calculateIsProposalThresholdReached(uint256 amountOfVotes, uint256 thresholdForProposal) internal view returns (bool) {
    if (totalAmountOfVotingPower < maxAmountOfVotingPower) {
      return
        amountOfVotes >=
        ((thresholdForProposal * maxAmountOfVotingPower) / precision);
    } else {
      return
        amountOfVotes >=
        ((thresholdForProposal * totalAmountOfVotingPower) / precision);
    }
  }

  function _calculateAbsoluteThresholdValue(uint256 thresholdNumerator) internal view returns (uint256) {
    if (totalAmountOfVotingPower < maxAmountOfVotingPower) {
      return ((thresholdNumerator * maxAmountOfVotingPower) / precision);
    } else {
      return ((thresholdNumerator * totalAmountOfVotingPower) / precision);
    }
  }

  // View functions
  function getVotingPowerManager() external view returns (address) {
    return votingPowerManager;
  }

  function getVoterVotingPower(address voter) public view returns (uint256) {
    return votingPower[voter];
  }

  function getTotalAmountOfVotingPower() external view returns (uint256) {
    return totalAmountOfVotingPower;
  }

  function getMaxAmountOfVotingPower() external view returns (uint256) {
    return maxAmountOfVotingPower;
  }

  function getPrecision() external view returns (uint256) {
    return precision;
  }

  function getTimestampToUnstake(address staker) external view returns(uint256) {
    return timeStampToUnstake[staker];
  }

  function _getDelegation(address delegator) public view returns(Delegation memory delegation) {
    delegation = delegations[delegator];
  }

  function getDelegatee(address delegator) external view returns(address) {
    Delegation memory delegation = _getDelegation(delegator);
    return delegation.delegatee;
  }

  function getAmountOfDelegatedVotingPower(address delegator) external view returns(uint256) {
    Delegation memory delegation = _getDelegation(delegator);
    return delegation.delegatedVotingPower;
  }

  function getFreezeAmountOfVotingPower(address delegator) external view returns(uint256) {
    Delegation memory delegation = _getDelegation(delegator);
    return delegation.freezedAmount;
  }

  function getUnfreezeTimestamp(address delegator) external view returns(uint256) {
    Delegation memory delegation = _getDelegation(delegator);
    return delegation.unfreezeTimestamp;
  }

  // return ProposalVoting struct
  function getProposalVotingVotesYes(string memory msName, uint256 proposalId)
    external
    view
    returns (uint256)
  {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votesYes;
  }

  function getProposalVotingVotesNo(string memory msName, uint256 proposalId)
    external
    view
    returns (uint256)
  {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votesNo;
  }

  function getProposalVotingDeadlineTimestamp(string memory msName, uint256 proposalId)
    external
    view
    returns (uint256)
  {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votingEndTimestamp;
  }

  function isHolderVotedForProposal(string memory msName, uint256 proposalId, address holder)
    external
    view
    returns (bool)
  {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votedAmount[holder] > 0;
  }

  function isVotingForProposalStarted(string memory msName, uint256 proposalId) external view returns (bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votingStarted;
  }

  function isVotingForProposalEnded(string memory msName, uint256 proposalId) external view returns(bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votingEndTimestamp <= block.timestamp;
  }
  // View function that args are taken from dao storage
  // Now i decide to get value from the back, but maybe i change my mind and
  // make call to dao inside functions
  function getAbsoluteThresholdByNumerator(uint256 thresholdNumerator) external view returns (uint256) {
    return _calculateAbsoluteThresholdValue(thresholdNumerator);
  }

  function isEnoughVotingPower(address holder, uint256 thresholdForInitiatorNumerator) external view returns (bool) {
    return _calculateIsEnoughVotingPower(holder, thresholdForInitiatorNumerator);
  }

  function isProposalThresholdReached(uint256 amountOfVotes, uint256 thresholdForProposal) external view returns (bool) {
    return _calculateIsProposalThresholdReached(amountOfVotes, thresholdForProposal);
  }
}
