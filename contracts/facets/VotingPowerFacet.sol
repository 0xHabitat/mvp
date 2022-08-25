// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IVotingPower} from "../interfaces/IVotingPower.sol";
import {LibVotingPower} from "../libraries/decisionSystem/votingPower/LibVotingPower.sol";

contract VotingPowerFacet is IVotingPower {
  function increaseVotingPower(address voter, uint256 amount) external override {
    LibVotingPower._increaseVotingPower(voter, amount);
  }

  function decreaseVotingPower(address voter, uint256 amount) external override {
    LibVotingPower._decreaseVotingPower(voter, amount);
  }

  function delegateVotingPower(address delegatee) external ovveride {
    LibVotingPower._delegateVotingPower(delegatee);
  }

  function undelegateVotingPower() external override {
    LibVotingPower._undelegateVotingPower();
  }

  function unfreezeVotingPower() external ovveride {
    LibVotingPower._unfreezeVotingPower();
  }

  // View functions
  function getVotingPowerManager() external view override returns (address) {
    return LibVotingPower._getVotingPowerManager();
  }

  function getVoterVotingPower(address voter) external view override returns (uint256) {
    return LibVotingPower._getVoterVotingPower(voter);
  }

  function getTotalAmountOfVotingPower() external view override returns (uint256) {
    return LibVotingPower._getTotalAmountOfVotingPower();
  }

  function getMaxAmountOfVotingPower() external view override returns (uint256) {
    return LibVotingPower._getMaxAmountOfVotingPower();
  }

  function getTimestampToUnstake(address staker) external view override returns (uint256) {
    return LibVotingPower._getTimestampToUnstake(staker);
  }

  function getDelegatee(address delegator) external view override returns(address) {
    return LibVotingPower._getDelegatee(delegator);
  }

  function getAmountOfDelegatedVotingPower(address delegator) external view override returns(uint256) {
    return LibVotingPower._getAmountOfDelegatedVotingPower(delegator);
  }

  function getFreezeAmountOfVotingPower(address delegator) external view override returns(uint256) {
    return LibVotingPower._getFreezeAmountOfVotingPower(delegator);
  }

  function getUnfreezeTimestamp(address delegator) external view override returns(uint256) {
    return LibVotingPower._getUnfreezeTimestamp(delegator);
  }
}
