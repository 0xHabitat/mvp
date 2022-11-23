// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDecider} from "../interfaces/decisionSystem/IDecider.sol";
import {DeciderVotingPower} from "../external/deciders/DeciderVotingPower.sol";

contract DeciderVotingPowerDeployer {

  event DeciderVotingPowerDeployed(address indexed deciderVotingPower);

  function deployDeciderVotingPower(
    address _dao,
    address _daoSetter,
    address _stakeContract,
    uint256 _precision
  ) external returns(address) {
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
