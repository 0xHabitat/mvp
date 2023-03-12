// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IVotingPower {
  /**
   * @notice Method increases voter amount of voting power.
   * @param voter Address, which voting power is increased.
   * @param amount voting power balance is increased.
   */
  function increaseVotingPower(address voter, uint256 amount) external;

  /**
   * @notice Method decreases voter amount of voting power.
   * @param voter Address, which voting power is decreased.
   * @param amount voting power balance is decreased.
   */
  function decreaseVotingPower(address voter, uint256 amount) external;

  /**
   * @notice Method moving all caller voting power to delegatee.
   * @param delegatee Address, which receives delegated voting power.
   */
  function delegateVotingPower(address delegatee) external;

  /**
   * @notice Method moving back to caller delegated voting power.
   */
  function undelegateVotingPower() external;

  /**
   * @notice Method unfreeze delegated voting power.
   */
  function unfreezeVotingPower() external;

  /**
   * @notice Returns voting power manager address.
   */
  function getVotingPowerManager() external view returns (address);

  /**
   * @notice Returns `voter` amount of voting power.
   */
  function getVoterVotingPower(address voter) external view returns (uint256);

  /**
   * @notice Returns total amount of voting power.
   */
  function getTotalAmountOfVotingPower() external view returns (uint256);

  /**
   * @notice Returns maximum amount of voting power.
   */
  function getMaxAmountOfVotingPower() external view returns (uint256);

  /**
   * @notice Returns timestamp, when `staker` is able to unstake tokens.
   */
  function getTimestampToUnstake(address staker) external view returns (uint256);

  /**
   * @notice Returns `delegator` delegatee address.
   */
  function getDelegatee(address delegator) external view returns (address);

  /**
   * @notice Returns 'delegator' amount of delegated voting power.
   */
  function getAmountOfDelegatedVotingPower(address delegator) external view returns (uint256);

  /**
   * @notice Returns 'delegator' amount of freezed voting power.
   */
  function getFreezeAmountOfVotingPower(address delegator) external view returns (uint256);

  /**
   * @notice Returns 'delegator' unfreeze timestamp.
   */
  function getUnfreezeTimestamp(address delegator) external view returns (uint256);
}
