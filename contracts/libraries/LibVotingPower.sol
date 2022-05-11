// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IVotingPower} from "../interfaces/IVotingPower.sol";
import {LibTreasury} from "./LibTreasury.sol";

library LibVotingPower {
  bytes32 constant VOTING_POWER_STORAGE_POSITION =
    keccak256("habitat.diamond.standard.votingPower.storage");

  /*
  struct VotingPower {
    address votingPowerManager;
    mapping(address => uint) votingPower;
    uint totalAmountOfVotingPower;
    uint maxAmountOfVotingPower;
  }
*/
  function votingPowerStorage() internal pure returns (IVotingPower.VotingPower storage vp) {
    bytes32 position = VOTING_POWER_STORAGE_POSITION;
    assembly {
      vp.slot := position
    }
  }

  function _increaseVotingPower(address voter, uint256 amount) internal {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    require(msg.sender == vp.votingPowerManager);
    // increase totalVotingPower
    vp.totalAmountOfVotingPower += amount;
    // increase voter voting power
    vp.votingPower[voter] += amount;
  }

  function _decreaseVotingPower(address voter, uint256 amount) internal {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    require(msg.sender == vp.votingPowerManager);
    require(
      !LibTreasury._hasVotedInActiveProposals(voter),
      "Cannot unstake until proposal is active"
    );
    // decrease totalVotingPower
    vp.totalAmountOfVotingPower -= amount;
    // decrease voter voting power
    vp.votingPower[voter] -= amount;
  }

  // View functions
  function _getVotingPowerManager() internal view returns (address) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.votingPowerManager;
  }

  function _getVoterVotingPower(address voter) internal view returns (uint256) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.votingPower[voter];
  }

  function _getTotalAmountOfVotingPower() internal view returns (uint256) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.totalAmountOfVotingPower;
  }

  function _getMaxAmountOfVotingPower() external view returns (uint256) {
    IVotingPower.VotingPower storage vp = votingPowerStorage();
    return vp.maxAmountOfVotingPower;
  }
}
