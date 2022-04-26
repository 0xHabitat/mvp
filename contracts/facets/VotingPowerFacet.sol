// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IVotingPower } from "../interfaces/IVotingPower.sol";
import { LibVotingPower } from "../libraries/LibVotingPower.sol";

contract VotingPowerFacet is IVotingPower {

  function increaseVotingPower(address voter, uint amount) external override {
    LibVotingPower._increaseVotingPower(voter, amount);
  }

  function decreaseVotingPower(address voter, uint amount) external override {
    LibVotingPower._decreaseVotingPower(voter, amount);
  }

  // View functions
  function getVotingPowerManager() external view override returns(address) {
    return LibVotingPower._getVotingPowerManager();
  }

  function getVoterVotingPower(address voter) external view override returns(uint) {
    return LibVotingPower._getVoterVotingPower(voter);
  }

  function getTotalAmountOfVotingPower() external view override returns(uint) {
    return LibVotingPower._getTotalAmountOfVotingPower();
  }

  function getMaxAmountOfVotingPower() external view override returns(uint) {
    return LibVotingPower._getMaxAmountOfVotingPower();
  }

}
