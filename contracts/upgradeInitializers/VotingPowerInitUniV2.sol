// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibVotingPower} from "../libraries/LibVotingPower.sol";
import {IVotingPower} from "../interfaces/IVotingPower.sol";
import {StakeContractERC20UniV2} from "../external/VotingPowerManagerERC20UniV2.sol";

contract VotingPowerInitUniV2 {
  event VotingPowerManagerCreated(
    address indexed votingPowerManager,
    address indexed diamondAddress
  );

  function initVotingPowerERC20UniV2(
    uint256 _maxAmountOfVotingPower,
    uint256 _stakeContrPrecision,
    address[] memory _governanceTokens,
    uint256[] memory _coefficients
  ) external {
    IVotingPower.VotingPower storage vp = LibVotingPower.votingPowerStorage();
    vp.maxAmountOfVotingPower = _maxAmountOfVotingPower;
    StakeContractERC20UniV2 stakeContract = new StakeContractERC20UniV2(
      address(this),
      _stakeContrPrecision,
      _governanceTokens,
      _coefficients
    );
    vp.votingPowerManager = address(stakeContract);
    emit VotingPowerManagerCreated(address(stakeContract), address(this));
  }
}
