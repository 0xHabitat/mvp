// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IVotingPower {

  struct VotingPower {
    address votingPowerManager;
    mapping(address => uint) votingPower;
    uint totalAmountOfVotingPower;
    uint maxAmountOfVotingPower;
  }
  // increasing voting power
  function increaseVotingPower(address voter, uint amount) external;

  // decreasing voting power
  function decreaseVotingPower(address voter, uint amount) external;

  // View functions
  function getVotingPowerManager() external view returns(address);

  function getVoterVotingPower(address voter) external view returns(uint);

  function getTotalAmountOfVotingPower() external view returns(uint);

  function getMaxAmountOfVotingPower() external view returns(uint);
}
