// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDecider} from "../interfaces/decisionSystem/IDecider.sol";
import {DeciderSigners} from "../external/deciders/DeciderSigners.sol";

/**
 * @title DeciderSignersDeployer - Allows to deploy a new decider contract. Decision type - Signers.
 * @author @roleengineer
 */
contract DeciderSignersDeployer {
  event DeciderSignersDeployed(address deciderSigners, address gnosisSafe);

  /**
   * @notice Deploys a new decider signers contract.
   * @param _dao Address of the dao diamond contract which will be using new contract as one of it's deciders.
   * @param _daoSetter Address that is allowed to set dao address one time, if it was not set at time of calling this function.
   * @param _gnosisSafe Address of the gnosis safe proxy contract, which will be used by decider signers contract as a source of decision power.
   * @return Address of the new decider signers contract.
   */
  function deployDeciderSigners(
    address _dao,
    address _daoSetter,
    address _gnosisSafe
  ) external returns (address) {
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
