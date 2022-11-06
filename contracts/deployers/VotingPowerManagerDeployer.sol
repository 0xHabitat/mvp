// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {StakeContractERC20UniV3} from "../external/VotingPowerManagerERC20UniV3.sol";

contract VotingPowerManagerDeployer {
  event VotingPowerManagerERC20UniV3Deployed(address stakeContract);

  function deployVotingPowerManagerERC20UniV3(
    address _nfPositionManager,
    address _governanceToken,
    address[] memory _legalPairTokens
  ) external returns(address) {
    StakeContractERC20UniV3 stakeContract = new StakeContractERC20UniV3(
      _nfPositionManager,
      _governanceToken,
      _legalPairTokens
    );
    emit VotingPowerManagerERC20UniV3Deployed(address(stakeContract));
    return address(stakeContract);
  }

}
