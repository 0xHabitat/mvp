// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MockVotingPowerHolder {
  address votingPowerManager;
  mapping (address => uint) public votingPower;
  mapping (address => bool) public voted;

  function setVPM(address vpm) external {
    votingPowerManager = vpm;
  }

  function setVoted(address holder) external {
    voted[holder] = true;
  }

  function increaseVotingPower(address holder, uint amount) external {
    require(msg.sender == votingPowerManager, "Only manager");
    votingPower[holder] += amount;
  }

  function decreaseVotingPower(address holder, uint amount) external {
    require(msg.sender == votingPowerManager, "Only manager");
    require(!voted[holder], "Cannot unstake until voted proposal is executed");
    votingPower[holder] -= amount;
  }
}
