// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDecider} from "../interfaces/decisionSystem/IDecider.sol";
import {DeciderSigners} from "../external/deciders/DeciderSigners.sol";

contract DeciderSignersDeployer {

  event DeciderSignersDeployed(address deciderSigners, address gnosisSafe);

  function deployDeciderSigners(
    address _dao,
    address _daoSetter,
    address _gnosisSafe
  ) external returns(address) {
    DeciderSigners deciderSigners = new DeciderSigners(
      _dao,
      _daoSetter,
      IDecider.DecisionType(3),
      _gnosisSafe
    );
    emit DeciderSignersDeployed(address(deciderSigners), _gnosisSafe);
    return address(deciderSigners);
  }
}
