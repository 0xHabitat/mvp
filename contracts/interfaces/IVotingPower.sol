// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IVotingPower {
  struct VotingPower {
    address votingPowerManager;
    mapping(address => uint256) votingPower;
    uint256 totalAmountOfVotingPower;
    uint256 maxAmountOfVotingPower;
  }

  // increasing voting power
  function increaseVotingPower(address voter, uint256 amount) external;

  // decreasing voting power
  function decreaseVotingPower(address voter, uint256 amount) external;

  // View functions
  function getVotingPowerManager() external view returns (address);

  function getVoterVotingPower(address voter) external view returns (uint256);

  function getTotalAmountOfVotingPower() external view returns (uint256);

  function getMaxAmountOfVotingPower() external view returns (uint256);
}
