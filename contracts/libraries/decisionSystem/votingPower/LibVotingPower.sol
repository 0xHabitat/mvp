// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IVotingPower} from "../../../interfaces/IVotingPower.sol";

library LibVotingPower {
  bytes32 constant VOTING_POWER_STORAGE_POSITION =
    keccak256("habitat.diamond.standard.votingPower.storage");

  /*
  struct VotingPower {
    address votingPowerManager;
    uint256 maxAmountOfVotingPower;
    uint256 totalAmountOfVotingPower;
    uint256 precision;
    mapping(address => uint) votingPower;
    mapping(address => uint) timeStampToUnstake;
    mapping(bytes32 => ProposalVoting) proposalsVoting;

    mapping(address => address) delegatorToDelegatee;
    mapping(address => uint256) delegatedVotingPower;
  }
*/
  function votingPowerStorage() internal pure returns (IVotingPower.VotingPower storage vp) {
    bytes32 position = VOTING_POWER_STORAGE_POSITION;
    assembly {
      vp.slot := position
    }
  }

  function _getProposalVoting(bytes32 proposalKey) internal pure returns(IVotingPower.ProposalVoting storage pV) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    pV = vp.proposalsVoting[proposalKey];
  }

  function _removeProposalVoting(bytes32 proposalKey) internal {
    IVotingPower.ProposalVoting storage pV = _getProposalVoting(proposalKey);
    delete pV.votingStarted;
    delete pV.votingEndTimestamp;
    delete pV.unstakeTimestamp;
    delete pV.votesYes;
    delete pV.votesNo;
    // rethink votedAmount
  }

  function _increaseVotingPower(address voter, uint256 amount) internal {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    require(msg.sender == vp.votingPowerManager);
    // increase totalVotingPower
    vp.totalAmountOfVotingPower += amount;
    // increase voter voting power
    vp.votingPower[voter] += amount;
  }

  function _decreaseVotingPower(address voter, uint256 amount) internal {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    require(msg.sender == vp.votingPowerManager);
    require(
      vp.timeStampToUnstake[voter] < block.timestamp,
      "Cannot unstake now."
    );
    // decrease totalVotingPower
    vp.totalAmountOfVotingPower -= amount;
    // decrease voter voting power
    vp.votingPower[voter] -= amount;
  }

  // delegates current amount of delegator voting power
  // if after first delegation voter has increased his amount of votingPower
  // he has to call this function again
  function _delegateVotingPower(address delegatee) internal {
    IVotingPower.VotingPower storage vp = votingPowerStorage();

    uint256 amountOfVotingPower = vp.votingPower[msg.sender];
    address currentDelegatee = vp.delegatorToDelegatee[msg.sender];
    require(amountOfVotingPower > 0, "Nothing to delegate");
    require(currentDelegatee == delegatee || currentDelegatee == address(0), "Undelegate before delegate to another delegatee.");
    // set delegatee of delegator
    vp.delegatorToDelegatee[msg.sender] = delegatee;
    // set to zero delegator voting power
    vp.votingPower[msg.sender] = uint256(0);
    // set how much voting power was delegated to delegatee from delegator
    vp.delegatedVotingPower[msg.sender] += amountOfVotingPower;
    // increase delegatee voting power
    vp.votingPower[delegatee] += amountOfVotingPower;
  }

  function _undelegateVotingPower() internal {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    address delegatee = vp.delegatorToDelegatee[msg.sender];
    require(delegatee != address(0), "Have not delegate yet.");
    // remove delegetee
    vp.delegatorToDelegatee[msg.sender] = address(0);
    // set timeStampToUnstake at least same as delegatee has
    uint delegateeTimeStampToUnstake = vp.timeStampToUnstake[delegatee];
    if (vp.timeStampToUnstake[msg.sender] < delegateeTimeStampToUnstake) {
      vp.timeStampToUnstake[msg.sender] = delegateeTimeStampToUnstake;
    }

    uint256 amountOfDelegatedVotingPower = delegatedVotingPower[msg.sender];
    // set to zero delegatedVotingPower
    delegatedVotingPower[msg.sender] = uint256(0);
    // take voting power back from delegatee
    vp.votingPower[delegatee] -= amountOfDelegatedVotingPower;
    // give voting power back to delegator
    vp.votingPower[msg.sender] += amountOfDelegatedVotingPower;
  }

  function _setTimestampToUnstake(address staker, uint256 timestamp) internal {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    if (vp.timeStampToUnstake[staker] < timestamp) {
      vp.timeStampToUnstake[staker] = timestamp;
    }
  }

  // View functions
  function _getVotingPowerManager() internal view returns (address) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.votingPowerManager;
  }

  function _getVoterVotingPower(address voter) internal view returns (uint256) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.votingPower[voter];
  }

  function _getTotalAmountOfVotingPower() internal view returns (uint256) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.totalAmountOfVotingPower;
  }

  function _getMaxAmountOfVotingPower() internal view returns (uint256) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.maxAmountOfVotingPower;
  }

  function _getPrecision() internal view returns (uint256) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.precision;
  }

  function _getTimestampToUnstake(address staker) internal view returns (uint256) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.timeStampToUnstake[staker];
  }

  function _getDelegatee(address delegator) internal view returns(address) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.delegatorToDelegatee[delegator];
  }

  function _getDelegatedVotingPower(address delegator) internal view returns(uint256) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.delegatedVotingPower[delegator];
  }

  function _calculateMinimumQuorum(uint64 minimumQuorum) internal pure returns (uint256) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return (uint256(minimumQuorum) * vp.maxAmountOfVotingPower) / vp.precision;
  }

  function _calculateIsQuorum(uint64 minimumQuorum) internal view returns (bool) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return
      (uint256(minimumQuorum) * vp.maxAmountOfVotingPower) / vp.precision <=
      vp.totalAmountOfVotingPower;
  }

  function _calculateIsEnoughVotingPower(address holder, uint64 thresholdForInitiator) internal view returns (bool) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return
      vp.votingPower[holder] >=
      ((uint256(thresholdForInitiator) * vp.totalAmountOfVotingPower) / vp.precision);
  }

  function _calculateIsProposalThresholdReached(uint256 amountOfVotes, uint64 thresholdForProposal) internal view returns (bool) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return
      amountOfVotes >=
      ((uint256(thresholdForProposal) * vp.totalAmountOfVotingPower) / vp.precision);
  }
}
