// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibVotingPower} from "../libraries/LibVotingPower.sol";
import {IVotingPower} from "../interfaces/IVotingPower.sol";
import {StakeContract} from "../external/VotingPowerManager.sol";

contract VotingPowerInit {
  event VotingPowerManagerCreated(
    address indexed votingPowerManager,
    address indexed diamondAddress
  );

  // default type
  function initVotingPowerType0(
    uint256 _maxAmountOfVotingPower,
    uint256 _stakeContrPrecision,
    address[] memory _governanceTokens,
    uint256[] memory _coefficients
  ) external {
    IVotingPower.VotingPower storage vp = LibVotingPower.votingPowerStorage();
    vp.maxAmountOfVotingPower = _maxAmountOfVotingPower;
    StakeContract stakeContract = new StakeContract(
      address(this),
      _stakeContrPrecision,
      _governanceTokens,
      _coefficients
    );
    vp.votingPowerManager = address(stakeContract);
    emit VotingPowerManagerCreated(address(stakeContract), address(this));
  }
}
