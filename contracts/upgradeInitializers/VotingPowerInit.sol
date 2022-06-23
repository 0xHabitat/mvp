// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibVotingPower} from "../libraries/LibVotingPower.sol";
import {IVotingPower} from "../interfaces/IVotingPower.sol";
import {StakeERC20Contract} from "../external/VotingPowerManager.sol";

contract VotingPowerInit {
  event VotingPowerManagerCreated(
    address indexed votingPowerManager,
    address indexed diamondAddress
  );

  // default type
  function initVotingPowerERC20Staked(
    uint256 _maxAmountOfVotingPower,
    uint256 _stakeContrPrecision,
    address[] memory _governanceTokens,
    uint256[] memory _coefficients
  ) external {
    IVotingPower.VotingPower storage vp = LibVotingPower.votingPowerStorage();
    vp.maxAmountOfVotingPower = _maxAmountOfVotingPower;
    StakeERC20Contract stakeERC20Contract = new StakeERC20Contract(
      address(this),
      _stakeContrPrecision,
      _governanceTokens,
      _coefficients
    );
    vp.votingPowerManager = address(stakeERC20Contract);
    emit VotingPowerManagerCreated(address(stakeERC20Contract), address(this));
  }
}
