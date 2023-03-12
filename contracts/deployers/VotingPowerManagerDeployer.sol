// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {StakeContractERC20UniV3} from "../external/VotingPowerManagerERC20UniV3.sol";

/**
 * @title VotingPowerManagerDeployer - Allows to deploy a new voting power manager contract.
 * @author @roleengineer
 */
contract VotingPowerManagerDeployer {
  event VotingPowerManagerERC20UniV3Deployed(address stakeContract);

  /**
   * @notice Deploys a voting power manager, which has staking functionality for erc20 token and it's uniV3 erc721 derivatives.
   * @param _nfPositionManager UniV3 non-fungible position manager address.
   * @param _governanceToken Address of erc20 token, which is an entry point to get voting power.
   * @param _legalPairTokens Array of addresses (erc20 tokens), which are considered to be a valid pair for uniV3 pool.
   *                         UniV3 positions (erc721 tokens), which has as underlying tokens _governanceToken and one of this array
   *                         are considered to be valid for staking and getting voting power.
   * @return Address of the newly deployed voting power manager contract.
   */
  function deployVotingPowerManagerERC20UniV3(
    address _nfPositionManager,
    address _governanceToken,
    address[] memory _legalPairTokens
  ) external returns (address) {
    StakeContractERC20UniV3 stakeContract = new StakeContractERC20UniV3(
      _nfPositionManager,
      _governanceToken,
      _legalPairTokens
    );
    emit VotingPowerManagerERC20UniV3Deployed(address(stakeContract));
    return address(stakeContract);
  }
}
