// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IVotingPower} from "../../../interfaces/IVotingPower.sol";

library LibVotingPower {
  bytes32 constant VOTING_POWER_STORAGE_POSITION =
    keccak256("habitat.diamond.standard.votingPower.storage");

  /*
  struct Delegation {
    address delegatee;
    uint256 delegatedVotingPower;
    uint256 freezedAmount;
    uint256 unfreezeTimestamp;
  }

  struct VotingPower {
    address votingPowerManager;
    uint256 maxAmountOfVotingPower;
    uint256 totalAmountOfVotingPower;
    uint256 precision;
    mapping(address => uint) votingPower;
    mapping(address => uint) timeStampToUnstake;
    mapping(address => Delegation) delegations;
    mapping(bytes32 => ProposalVoting) proposalsVoting;
  }
*/
  function votingPowerStorage() internal pure returns (IVotingPower.VotingPower storage vp) {
    bytes32 position = VOTING_POWER_STORAGE_POSITION;
    assembly {
      vp.slot := position
    }
  }

  function _getProposalVoting(bytes32 proposalKey) internal returns(IVotingPower.ProposalVoting storage pV) {
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
    require(vp.timeStampToUnstake[msg.sender] < block.timestamp, "Wait timestamp to delegate");
    uint256 amountOfVotingPower = vp.votingPower[msg.sender];
    require(amountOfVotingPower > 0, "Nothing to delegate");

    IVotingPower.Delegation storage delegation = vp.delegations[msg.sender];

    require(delegation.delegatee == delegatee || delegation.delegatee == address(0), "Undelegate before delegate to another delegatee.");
    // set delegatee of delegator
    delegation.delegatee = delegatee;
    // set to zero delegator voting power
    vp.votingPower[msg.sender] = uint256(0);
    // set how much voting power was delegated to delegatee from delegator
    delegation.delegatedVotingPower += amountOfVotingPower;
    // increase delegatee voting power
    vp.votingPower[delegatee] += amountOfVotingPower;
  }

  function _undelegateVotingPower() internal {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    IVotingPower.Delegation storage delegation = vp.delegations[msg.sender];
    require(delegation.delegatee != address(0), "Have not delegate yet.");
    require(delegation.delegatedVotingPower > 0, "Nothing to undelegate.");
    // remove delegetee
    address delegatee = delegation.delegatee;
    delegation.delegatee = address(0);
    // set timeStampToUnstake at least same as delegatee has
    uint delegateeTimeStampToUnstake = vp.timeStampToUnstake[delegatee];
    if (vp.timeStampToUnstake[msg.sender] < delegateeTimeStampToUnstake) {
      vp.timeStampToUnstake[msg.sender] = delegateeTimeStampToUnstake;
    }

    uint256 amountOfDelegatedVotingPower = delegation.delegatedVotingPower;
    // set to zero delegatedVotingPower
    delegation.delegatedVotingPower = uint256(0);
    // take voting power back from delegatee
    vp.votingPower[delegatee] -= amountOfDelegatedVotingPower;
    if (delegateeTimeStampToUnstake < block.timestamp) {
      // give voting power back to delegator
      vp.votingPower[msg.sender] += amountOfDelegatedVotingPower;
    } else {
      // freeze votingPower with timestamp to unfreeze
      delegation.unfreezeTimestamp = delegateeTimeStampToUnstake;
      delegation.freezedAmount += amountOfDelegatedVotingPower;
    }
  }

  function _unfreezeVotingPower() internal {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    IVotingPower.Delegation storage delegation = vp.delegations[msg.sender];

    require(delegation.unfreezeTimestamp < block.timestamp, "Wait timestamp to unfreeze");
    uint amountOfVotingPower = delegation.freezedAmount;
    delegation.freezedAmount = 0;
    vp.votingPower[msg.sender] += amountOfVotingPower;
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

  function _getDelegation(address delegator) internal view returns(IVotingPower.Delegation memory delegation) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    delegation = vp.delegations[delegator];
  }

  function _getDelegatee(address delegator) internal view returns(address) {
    IVotingPower.Delegation memory delegation = _getDelegation(delegator);
    return delegation.delegatee;
  }

  function _getAmountOfDelegatedVotingPower(address delegator) internal view returns(uint256) {
    IVotingPower.Delegation memory delegation = _getDelegation(delegator);
    return delegation.delegatedVotingPower;
  }

  function _getFreezeAmountOfVotingPower(address delegator) internal view returns(uint256) {
    IVotingPower.Delegation memory delegation = _getDelegation(delegator);
    return delegation.freezedAmount;
  }

  function _getUnfreezeTimestamp(address delegator) internal view returns(uint256) {
    IVotingPower.Delegation memory delegation = _getDelegation(delegator);
    return delegation.unfreezeTimestamp;
  }

  function _calculateIsEnoughVotingPower(address holder, uint64 thresholdForInitiator) internal returns (bool) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    if (vp.totalAmountOfVotingPower < vp.maxAmountOfVotingPower) {
      return
        vp.votingPower[holder] >=
        ((uint256(thresholdForInitiator) * vp.maxAmountOfVotingPower) / vp.precision);
    } else {
      return
        vp.votingPower[holder] >=
        ((uint256(thresholdForInitiator) * vp.totalAmountOfVotingPower) / vp.precision);
    }
  }

  function _calculateIsProposalThresholdReached(uint256 amountOfVotes, uint64 thresholdForProposal) internal returns (bool) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    if (vp.totalAmountOfVotingPower < vp.maxAmountOfVotingPower) {
      return
        amountOfVotes >=
        ((uint256(thresholdForProposal) * vp.maxAmountOfVotingPower) / vp.precision);
    } else {
      return
        amountOfVotes >=
        ((uint256(thresholdForProposal) * vp.totalAmountOfVotingPower) / vp.precision);
    }
  }
}
