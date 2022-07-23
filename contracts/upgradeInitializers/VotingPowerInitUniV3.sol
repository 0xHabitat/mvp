// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibVotingPower} from "../libraries/LibVotingPower.sol";
import {IVotingPower} from "../interfaces/IVotingPower.sol";
import {StakeContractERC20UniV3} from "../external/VotingPowerManagerERC20UniV3.sol";

contract VotingPowerInitUniV3 {
  event VotingPowerManagerCreated(
    address indexed votingPowerManager,
    address indexed diamondAddress
  );

  function initVotingPowerERC20UniV3(
    uint256 _maxAmountOfVotingPower,
    address _nfPositionManager,
    address _governanceToken,
    address[] memory _legalPairTokens
  ) external {
    IVotingPower.VotingPower storage vp = LibVotingPower.votingPowerStorage();
    vp.maxAmountOfVotingPower = _maxAmountOfVotingPower;
    StakeContractERC20UniV3 stakeContract = new StakeContractERC20UniV3(
      address(this),
      _nfPositionManager,
      _governanceToken,
      _legalPairTokens
    );
    vp.votingPowerManager = address(stakeContract);
    emit VotingPowerManagerCreated(address(stakeContract), address(this));
  }
}
