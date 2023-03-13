// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDecider} from "../interfaces/decisionSystem/IDecider.sol";
import {DeciderVotingPower} from "../external/deciders/DeciderVotingPower.sol";

/**
 * @title DeciderVotingPowerDeployer - Allows to deploy a new decider contract. Decision type - Voting Power.
 * @author @roleengineer
 */
contract DeciderVotingPowerDeployer {
  event DeciderVotingPowerDeployed(address indexed deciderVotingPower);

  /**
   * @notice Deploys a new decider voting power contract.
   * @param _dao Address of the dao diamond contract which will be using new contract as one of it's deciders.
   * @param _daoSetter Address that is allowed to set dao address one time, if it was not set at time of calling this function.
   * @param _stakeContract Address of the stake contract, which is allowed to set (increase/decrease) voting power balances inside decider.
   * @param _precision Is used in calculations related to threshold. Threshold value
   *                   which represents threshold percentage: 50% = 0.5 * _precision.
   *                   Denominator for the threshold values. Multiplier for the threshold percentages.
   * @return Address of the new decider voting power contract.
   */
  function deployDeciderVotingPower(
    address _dao,
    address _daoSetter,
    address _stakeContract,
    uint256 _precision
  ) external returns (address) {
    DeciderVotingPower deciderVotingPower = new DeciderVotingPower(
      _dao,
      _daoSetter,
      IDecider.DecisionType(2),
      _stakeContract,
      _precision
    );

    emit DeciderVotingPowerDeployed(address(deciderVotingPower));
    return address(deciderVotingPower);
  }
}
