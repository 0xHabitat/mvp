// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IVotingPower {

  // increasing voting power
  function increaseVotingPower(address voter, uint256 amount) external;

  // decreasing voting power
  function decreaseVotingPower(address voter, uint256 amount) external;

  function delegateVotingPower(address delegatee) external;

  function undelegateVotingPower() external;

  function unfreezeVotingPower() external;

  // View functions
  function getVotingPowerManager() external view returns (address);

  function getVoterVotingPower(address voter) external view returns (uint256);

  function getTotalAmountOfVotingPower() external view returns (uint256);

  function getMaxAmountOfVotingPower() external view returns (uint256);

  function getTimestampToUnstake(address staker) external view returns(uint256);

  function getDelegatee(address delegator) external view returns(address);

  function getAmountOfDelegatedVotingPower(address delegator) external view returns(uint256);

  function getFreezeAmountOfVotingPower(address delegator) external view returns(uint256);

  function getUnfreezeTimestamp(address delegator) external view returns(uint256);
}
