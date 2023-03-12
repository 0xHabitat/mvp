// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {BaseDecider} from "./BaseDecider.sol";
import {IVotingPower} from "../../interfaces/decisionSystem/IVotingPower.sol";
import {VotingPowerSpecificData} from "../../interfaces/decisionSystem/SpecificDataStructs.sol";

interface IERC20 {
  function totalSupply() external view returns (uint256);
}

interface IVotingPowerManager {
  function governanceToken() external view returns (address);
}

/**
 * @title DeciderVotingPower - Base part of Voting Power Decision System - onchain voting.
 * @notice Inherits BaseDecider and implements its function by overridding in the conve of voting power decision system.
 *         Contract relies on StakeContractERC20UniV3 (called VotingPowerManager) to define accounts voting power.
 *         Contract has its own voting power delegation logic.
 *         Contract accounts proposal votings on behalf of the DAO.
 * @dev Interactions flow:
 *      - Accounts, which have staked governance token and/or uniV3 positions to
 *        StakeContractERC20UniV3 are getting voting power inside this contract.
 *      - Accounts are interacting with the DAO contract. Creation proposals related
 *        to DAO Modules, which current decision type is VotingPowerERC20, makes DAO
 *        call this contract and ask if account is able to create proposal and if yes
 *        ask to create voting and account to vote.
 *      - Same applies for the whole decision process (proposal create,
 *        decide on, accept or reject, execute): account interacts with a DAO,
 *        DAO interacts with this contract, this contract based on its state and data
 *        received from the DAO conducts the decision process by its own logic.
 *      - Accounts interacts directly with this contract about delegation, getting
 *        proposal votings state and other view functions.
 *      - Accounts are able to unstake their tokens any time, if they have not voted.
 *      - Account which has voted on the active proposal, has to wait unstakeTimestamp
 *        until be able to unstake staked tokens.
 * @author @roleengineer
 */
contract DeciderVotingPower is BaseDecider, IVotingPower {
  struct Delegation {
    address delegatee;
    uint256 delegatedVotingPower;
    uint256 freezedAmount;
    uint256 unfreezeTimestamp;
  }

  struct ProposalVoting {
    bool votingStarted;
    mapping(address => uint256) votedAmount; // rethink
    uint256 votingEndTimestamp;
    uint256 unstakeTimestamp;
    uint256 votesYes;
    uint256 votesNo;
  }

  event NewVoting(bytes32 indexed proposalKey, uint256 votingEndTimestamp);

  event Voted(address indexed voter, string indexed msName, uint256 indexed proposalId, bool vote);

  event FinalVotes(
    string indexed msName,
    uint256 indexed proposalId,
    uint256 votesYes,
    uint256 votesNo
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

  /*//////////////////////////////////////////////////////////////
                    DAO INTERACTION FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns true, if stake and dao contracts are set and govtoken totalSupply is not 0.
   * @return True, if setup is completed.
   */
  function isSetupComplete() external override onlyDAO returns (bool) {
    // maybe here we need more complex logic?
    return
      votingPowerManager != address(0) && dao != address(0) && maxAmountOfVotingPower != uint256(0);
  }

  /**
   * @notice DeciderVotingPower does not have a direct caller.
   * @return Address 0x0.
   */
  function directCaller() external override onlyDAO returns (address) {
    return address(0);
  }

  /**
   * @notice DeciderVotingPower does not have a direct caller.
   * @return False.
   */
  function isDirectCallerSetup() external override onlyDAO returns (bool) {
    return false;
  }

  /**
   * @notice DeciderVotingPower does not have a direct caller.
   * @return Revert the call.
   */
  function directCallerExecutionTimestamp(
    bytes memory specificData
  ) external override onlyDAO returns (uint256) {
    revert(
      "direct caller is not a part of voting power decision system, how do you call from address(0)?"
    );
  }

  /**
   * @notice Method defines, if the `caller` is allowed to create proposal
   *         by receiving thresholdForInitiator from the DAO and calculating, if
   *         `caller` has enough voting power to reach the threshold.
   *         Threshold for initiator is individual for each DAO Module.
   * @param caller Address, which is initiating proposal creation.
   * @param specificData Voting power specific data struct contains 4 uint256 (thresholdForInitiator, thresholdForProposal, secondsProposalVotingPeriod, secondsProposalExecutionDelayPeriod).
   * @return True, if caller is allowed to create proposal.
   * @return String, explaining the reason, if caller is not allowed.
   */
  function isCallerAllowedToCreateProposal(
    address caller,
    bytes memory specificData
  ) external override onlyDAO returns (bool, string memory) {
    VotingPowerSpecificData memory vpsd = abi.decode(specificData, (VotingPowerSpecificData));
    bool allowed = _calculateIsEnoughVotingPower(caller, vpsd.thresholdForInitiator);
    return allowed ? (allowed, "") : (allowed, "Not enough voting power to create proposal.");
  }

  /**
   * @notice Method initiates proposal voting, based on secondsProposalVotingPeriod and
   *         secondsProposalExecutionDelayPeriod (individual for each DAO Module)
   *         calculates votingEndTimestamp and executionTimestamp, sets unstakeTimestamp
   *         for voters that will vote on this proposal.
   * @dev Each proposal is unique, we store it in a mapping by the key, which is
   *      calculating by keccak256 function taking module name and proposal id.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param specificData Voting power specific data struct contains 4 uint256 (thresholdForInitiator, thresholdForProposal, secondsProposalVotingPeriod, secondsProposalExecutionDelayPeriod).
   * @return executionTimestamp The timestamp, when proposal could be executed is returned to the DAO.
   */
  function initiateDecisionProcess(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external override onlyDAO returns (uint256 executionTimestamp) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);

    VotingPowerSpecificData memory vpsd = abi.decode(specificData, (VotingPowerSpecificData));

    proposalVoting.votingStarted = true;

    proposalVoting.votingEndTimestamp = vpsd.secondsProposalVotingPeriod + block.timestamp;
    executionTimestamp =
      vpsd.secondsProposalExecutionDelayPeriod +
      proposalVoting.votingEndTimestamp;

    proposalVoting.unstakeTimestamp = executionTimestamp;
    emit NewDecisionProcess(proposalKey, msName, proposalId);
    emit NewVoting(proposalKey, proposalVoting.votingEndTimestamp);
  }

  /**
   * @notice Method register the valid vote - add amount of `decider` voting power
   *         to proposal voting yes or no depend on `decision`.
   *         Valid means: voting on proposal is started and is not ended.
   *         Also sets `decider` new unstakeTimestamp.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param decider Address that is voting.
   * @param decision True - for proposal, false - against proposal.
   */
  function decideOnProposal(
    string memory msName,
    uint256 proposalId,
    address decider,
    bool decision
  ) external override onlyDAO {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    require(proposalVoting.votingStarted, "No voting rn.");
    require(proposalVoting.votingEndTimestamp >= block.timestamp, "Voting period is ended.");
    uint256 deciderVotingPower = getVoterVotingPower(decider);
    require(proposalVoting.votedAmount[decider] < deciderVotingPower, "Already voted.");
    _setTimestampToUnstake(decider, proposalVoting.unstakeTimestamp);
    uint256 difference = deciderVotingPower - proposalVoting.votedAmount[decider];

    proposalVoting.votedAmount[decider] = deciderVotingPower; // rething this
    if (decision) {
      proposalVoting.votesYes += difference;
    } else {
      proposalVoting.votesNo += difference;
    }
    emit Voted(decider, msName, proposalId, decision);
  }

  /**
   * @notice Method accepts or rejects the proposal, after voting period is ended,
   *         by analizing the voting results and thresholdForProposal (received from the DAO).
   *         Proposal voting is loged in event and cleaned from the storage.
   *         Sets true in canBeExecuted mapping for accepted proposal (additional security for the DAO contract).
   * @dev Must be called right after the proposal voting period deadline is expired.
   *      Otherwise can be manipulated (e.g. governance effects proposal threshold).
   *      Best to have offchain service that will call immediately.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param specificData Voting power specific data struct contains 4 uint256 (thresholdForInitiator, thresholdForProposal, secondsProposalVotingPeriod, secondsProposalExecutionDelayPeriod).
   * @return True, if proposal is accepted is returned to the DAO contract.
   */
  function acceptOrRejectProposal(
    string memory msName,
    uint256 proposalId,
    bytes memory specificData
  ) external override onlyDAO returns (bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    require(proposalVoting.votingStarted, "No voting.");
    require(
      proposalVoting.votingEndTimestamp <= block.timestamp,
      "Voting period is not ended yet."
    );
    VotingPowerSpecificData memory vpsd = abi.decode(specificData, (VotingPowerSpecificData));

    uint256 votesYes = proposalVoting.votesYes;
    uint256 votesNo = proposalVoting.votesNo;
    _removeProposalVoting(proposalKey);
    uint256 thresholdForProposal = vpsd.thresholdForProposal;
    bool proposalThresholdReachedYes = _calculateIsProposalThresholdReached(
      votesYes,
      thresholdForProposal
    );
    bool proposalThresholdReachedNo = _calculateIsProposalThresholdReached(
      votesNo,
      thresholdForProposal
    );
    emit FinalVotes(msName, proposalId, votesYes, votesNo);
    if (proposalThresholdReachedYes && proposalThresholdReachedNo) {
      if (votesYes > votesNo) {
        // accept proposal
        canBeExecuted[proposalKey] = true;
        return true;
      }
    } else if (proposalThresholdReachedYes) {
      // accept proposal
      canBeExecuted[proposalKey] = true;
      return true;
    }
    // proposal rejected
    return false;
  }

  /**
   * @notice Method executes accepted proposal as DAO accepts execution call
   *         only from decider contracts. Checks if proposal canBeExecuted.
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
                      DECIDER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Method is called by StakeContractERC20UniV3 (when voter stakes tokens)
   *         and increases voter amount of voting power.
   * @param voter Address, which is beneficiary of staking tokens.
   * @param amount voting power balance is increased.
   */
  function increaseVotingPower(address voter, uint256 amount) external {
    require(msg.sender == votingPowerManager);
    // increase totalVotingPower
    totalAmountOfVotingPower += amount;
    // increase voter voting power
    votingPower[voter] += amount;
  }

  /**
   * @notice Method is called by StakeContractERC20UniV3 (when voter unstakes tokens)
   *         and decreases voter amount of voting power.
   * @param voter Address, which is unstaking tokens.
   * @param amount voting power balance is decreased.
   */
  function decreaseVotingPower(address voter, uint256 amount) external {
    require(msg.sender == votingPowerManager);
    require(timeStampToUnstake[voter] <= block.timestamp, "Cannot unstake now.");
    // decrease totalVotingPower
    totalAmountOfVotingPower -= amount;
    // decrease voter voting power
    votingPower[voter] -= amount;
  }

  /**
   * @notice Method moving all caller voting power to delegatee and accounts
   *         this action.
   * @dev Able to have only one delegatee, to change delegatee first have to undelegate.
   * @param delegatee Address, which receives delegated voting power.
   */
  function delegateVotingPower(address delegatee) external {
    require(timeStampToUnstake[msg.sender] < block.timestamp, "Wait timestamp to delegate");
    uint256 amountOfVotingPower = votingPower[msg.sender];
    require(amountOfVotingPower > 0, "Nothing to delegate");

    Delegation storage delegation = delegations[msg.sender];

    require(
      delegation.delegatee == delegatee || delegation.delegatee == address(0),
      "Undelegate before delegate to another delegatee."
    );
    // set delegatee of delegator
    delegation.delegatee = delegatee;
    // set to zero delegator voting power
    votingPower[msg.sender] = uint256(0);
    // set how much voting power was delegated to delegatee from delegator
    delegation.delegatedVotingPower += amountOfVotingPower;
    // increase delegatee voting power
    votingPower[delegatee] += amountOfVotingPower;
  }

  /**
   * @notice Method moving back to caller delegated voting power and accounts
   *         this action. If current timestamp is less then delegatee unstakeTimestamp,
   *         then delegated voting power is freezed until unfreezeTimestamp.
   * @dev Delegator gets same unstakeTimestamp as delegatee, if it is bigger.
   */
  function undelegateVotingPower() external {
    Delegation storage delegation = delegations[msg.sender];
    require(delegation.delegatee != address(0), "Have not delegate yet.");
    require(delegation.delegatedVotingPower > 0, "Nothing to undelegate.");
    // remove delegetee
    address delegatee = delegation.delegatee;
    delegation.delegatee = address(0);
    // set timeStampToUnstake at least same as delegatee has
    uint256 delegateeTimeStampToUnstake = timeStampToUnstake[delegatee];
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

  /**
   * @notice Method unfreeze delegated voting power after unfreezeTimestamp.
   */
  function unfreezeVotingPower() external {
    Delegation storage delegation = delegations[msg.sender];

    require(delegation.unfreezeTimestamp < block.timestamp, "Wait timestamp to unfreeze");
    uint256 amountOfVotingPower = delegation.freezedAmount;
    delegation.freezedAmount = 0;
    votingPower[msg.sender] += amountOfVotingPower;
  }

  /*//////////////////////////////////////////////////////////////
                      INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @dev Internal method that sets new timestamp to unstake.
   */
  function _setTimestampToUnstake(address staker, uint256 timestamp) internal {
    if (timeStampToUnstake[staker] < timestamp) {
      timeStampToUnstake[staker] = timestamp;
    }
  }

  /**
   * @dev Internal method that returns ProposalVoting struct by proposalKey.
   */
  function _getProposalVoting(
    bytes32 proposalKey
  ) internal view returns (ProposalVoting storage pV) {
    pV = proposalsVoting[proposalKey];
  }

  /**
   * @notice Removes proposal voting struct from storage.
   * @dev Doubts. Rethink if remove as well. Now i think that we will not remove voting,
   *      because we want the source of results as we don't use a server and parsing blockchain logs.
   *      We just put votingStarted false (looks enough to protect doublespending).
   */
  function _removeProposalVoting(bytes32 proposalKey) internal {
    ProposalVoting storage pV = _getProposalVoting(proposalKey);
    delete pV.votingStarted;
    delete pV.votingEndTimestamp;
    delete pV.unstakeTimestamp;
    delete pV.votesYes;
    delete pV.votesNo;
    // rethink votedAmount
  }

  /**
   * @dev Returns true, if `holder` has enough voting power to reach `thresholdForInitiator`.
   */
  function _calculateIsEnoughVotingPower(
    address holder,
    uint256 thresholdForInitiator
  ) internal view returns (bool) {
    if (totalAmountOfVotingPower < maxAmountOfVotingPower) {
      return votingPower[holder] >= ((thresholdForInitiator * maxAmountOfVotingPower) / precision);
    } else {
      return
        votingPower[holder] >= ((thresholdForInitiator * totalAmountOfVotingPower) / precision);
    }
  }

  /**
   * @dev Returns true, if `amountOfVotes` is enough to reach `thresholdForProposal`.
   */
  function _calculateIsProposalThresholdReached(
    uint256 amountOfVotes,
    uint256 thresholdForProposal
  ) internal view returns (bool) {
    if (totalAmountOfVotingPower < maxAmountOfVotingPower) {
      return amountOfVotes >= ((thresholdForProposal * maxAmountOfVotingPower) / precision);
    } else {
      return amountOfVotes >= ((thresholdForProposal * totalAmountOfVotingPower) / precision);
    }
  }

  /**
   * @dev Returns calculated absolute threshold value in voting power.
   */
  function _calculateAbsoluteThresholdValue(
    uint256 thresholdNumerator
  ) internal view returns (uint256) {
    if (totalAmountOfVotingPower < maxAmountOfVotingPower) {
      return ((thresholdNumerator * maxAmountOfVotingPower) / precision);
    } else {
      return ((thresholdNumerator * totalAmountOfVotingPower) / precision);
    }
  }

  /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns voting power manager (stake contract) address.
   */
  function getVotingPowerManager() external view returns (address) {
    return votingPowerManager;
  }

  /**
   * @notice Returns `voter` amount of voting power.
   */
  function getVoterVotingPower(address voter) public view returns (uint256) {
    return votingPower[voter];
  }

  /**
   * @notice Returns total amount of voting power (depends on staking activity).
   */
  function getTotalAmountOfVotingPower() external view returns (uint256) {
    return totalAmountOfVotingPower;
  }

  /**
   * @notice Returns maximum amount of voting power, equals totalSupply of governance token.
   * @dev totalAmountOfVotingPower could be biger than maximum, because of ability to stake uniV3 positions.
   */
  function getMaxAmountOfVotingPower() external view returns (uint256) {
    return maxAmountOfVotingPower;
  }

  /**
   * @notice Returns precision value. Denominator for the threshold values. Multiplier for the threshold percentages.
   */
  function getPrecision() external view returns (uint256) {
    return precision;
  }

  /**
   * @notice Returns timestamp, when `staker` is able to unstake tokens.
   */
  function getTimestampToUnstake(address staker) external view returns (uint256) {
    return timeStampToUnstake[staker];
  }

  /**
   * @notice Returns Delegation struct filled with values related to `delegator`.
   * @param delegator Address which has delegated voting power
   * @return delegation struct containing delegatee address, amount of delegatedVotingPower,
   *                    freezedAmount of voting power and unfreezeTimestamp.
   */
  function _getDelegation(address delegator) public view returns (Delegation memory delegation) {
    delegation = delegations[delegator];
  }

  /**
   * @notice Returns `delegator` delegatee address.
   */
  function getDelegatee(address delegator) external view returns (address) {
    Delegation memory delegation = _getDelegation(delegator);
    return delegation.delegatee;
  }

  /**
   * @notice Returns 'delegator' amount of delegated voting power.
   */
  function getAmountOfDelegatedVotingPower(address delegator) external view returns (uint256) {
    Delegation memory delegation = _getDelegation(delegator);
    return delegation.delegatedVotingPower;
  }

  /**
   * @notice Returns 'delegator' amount of freezed voting power.
   */
  function getFreezeAmountOfVotingPower(address delegator) external view returns (uint256) {
    Delegation memory delegation = _getDelegation(delegator);
    return delegation.freezedAmount;
  }

  /**
   * @notice Returns 'delegator' unfreeze timestamp.
   */
  function getUnfreezeTimestamp(address delegator) external view returns (uint256) {
    Delegation memory delegation = _getDelegation(delegator);
    return delegation.unfreezeTimestamp;
  }

  /**
   * ProposalVoting struct
   * @notice Returns amount of votes yes given to the proposal.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @return amount of votes yes given to the proposal.
   */
  function getProposalVotingVotesYes(
    string memory msName,
    uint256 proposalId
  ) external view returns (uint256) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votesYes;
  }

  /**
   * ProposalVoting struct
   * @notice Returns amount of votes no given to the proposal.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @return amount of votes no given to the proposal.
   */
  function getProposalVotingVotesNo(
    string memory msName,
    uint256 proposalId
  ) external view returns (uint256) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votesNo;
  }

  /**
   * ProposalVoting struct
   * @notice Returns proposal voting period deadline timestamp.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @return proposal voting period deadline timestamp.
   */
  function getProposalVotingDeadlineTimestamp(
    string memory msName,
    uint256 proposalId
  ) external view returns (uint256) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votingEndTimestamp;
  }

  /**
   * ProposalVoting struct
   * @notice Returns true, if `holder` has voted for a proposal.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @param holder Address, which has voted for a proposal.
   * @return true, if `holder` has voted for a `msName` proposal `proposalId`.
   */
  function isHolderVotedForProposal(
    string memory msName,
    uint256 proposalId,
    address holder
  ) external view returns (bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votedAmount[holder] > 0;
  }

  /**
   * ProposalVoting struct
   * @notice Returns true, if proposal voting period is already started.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @return true, if voting period for a `msName` proposal `proposalId` is started.
   */
  function isVotingForProposalStarted(
    string memory msName,
    uint256 proposalId
  ) external view returns (bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votingStarted;
  }

  /**
   * ProposalVoting struct
   * @notice Returns true, if proposal voting period is already ended.
   * @param msName DAO Module name, proposal is related to.
   * @param proposalId The id of proposal, unique to each module. Starts with 1, next + 1.
   * @return true, if voting period for a `msName` proposal `proposalId` is ended.
   */
  function isVotingForProposalEnded(
    string memory msName,
    uint256 proposalId
  ) external view returns (bool) {
    bytes32 proposalKey = keccak256(abi.encodePacked(msName, proposalId));
    ProposalVoting storage proposalVoting = _getProposalVoting(proposalKey);
    return proposalVoting.votingEndTimestamp <= block.timestamp;
  }

  /**
   * @notice Returns calculated absolute threshold value in voting power.
   * @dev Doubts. View function that args are taken from dao storage.
   *      Now i decide to get value from the back, but maybe i change my mind and
   *      make call to dao inside functions.
   */
  function getAbsoluteThresholdByNumerator(
    uint256 thresholdNumerator
  ) external view returns (uint256) {
    return _calculateAbsoluteThresholdValue(thresholdNumerator);
  }

  /**
   * @notice Returns true, if `holder` has enough voting power to reach `thresholdForInitiator`.
   */
  function isEnoughVotingPower(
    address holder,
    uint256 thresholdForInitiatorNumerator
  ) external view returns (bool) {
    return _calculateIsEnoughVotingPower(holder, thresholdForInitiatorNumerator);
  }

  /**
   * @notice Returns true, if `amountOfVotes` is enough to reach `thresholdForProposal`.
   */
  function isProposalThresholdReached(
    uint256 amountOfVotes,
    uint256 thresholdForProposal
  ) external view returns (bool) {
    return _calculateIsProposalThresholdReached(amountOfVotes, thresholdForProposal);
  }
}
