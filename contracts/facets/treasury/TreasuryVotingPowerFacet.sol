// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITreasuryVotingPower } from "../../interfaces/treasury/ITreasuryVotingPower.sol";
import { LibTreasury } from "../../libraries/LibTreasury.sol";
import { ITreasury } from "../../interfaces/treasury/ITreasury.sol"; // remove when move hasVoted

contract TreasuryVotingPowerFacet is ITreasuryVotingPower {

  function increaseVotingPower(address voter, uint amount) external override {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    require(msg.sender == tvp.votingPowerManager);
    // increase totalVotingPower
    tvp.totalAmountOfVotingPower += amount;
    // increase voter voting power
    tvp.votingPower[voter] += amount;
  }

  function decreaseVotingPower(address voter, uint amount) external override {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    require(msg.sender == tvp.votingPowerManager);
    require(!hasVotedInActiveProposals(voter), "Cannot unstake until proposal is active");
    // decrease totalVotingPower
    tvp.totalAmountOfVotingPower -= amount;
    // decrease voter voting power
    tvp.votingPower[voter] -= amount;
  }
  // TODO this function the only one that is required ITreasury. Decide let it be here or move.
  function hasVotedInActiveProposals(address voter) public view override returns(bool) {
    ITreasury.Treasury storage treasury = LibTreasury.treasuryStorage();

    if (treasury.activeProposalsIds.length == 0) {
      return false;
    }

    for (uint i = 0; i < treasury.activeProposalsIds.length; i++) {
      uint proposalId = treasury.activeProposalsIds[i];
      bool hasVoted = treasury.proposalVotings[proposalId].voted[voter];
      if (hasVoted) {
        return true;
      }
    }

    return false;
  }

  // View functions

  function getVoterVotingPower(address voter) public view override returns(uint) {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.votingPower[voter];
  }

  function getTotalAmountOfVotingPower() external view override returns(uint) {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.totalAmountOfVotingPower;
  }

  function getMinimumQuorum() external view override returns(uint) {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.minimumQuorum;
  }

  function isQourum() external view override returns(bool) {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.totalAmountOfVotingPower >= tvp.minimumQuorum;
  }

  function isEnoughVotingPower(address holder) external view override returns(bool) {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    uint voterPower = getVoterVotingPower(holder);
    return voterPower >= (uint(tvp.thresholdForInitiator) * tvp.totalAmountOfVotingPower / uint(tvp.precision));
  }

  function isProposalThresholdReached(uint amountOfVotes) external view override returns(bool) {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return amountOfVotes >= (tvp.thresholdForProposal * tvp.totalAmountOfVotingPower / uint(tvp.precision));
  }
}
