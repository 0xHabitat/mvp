// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITreasuryVotingPower } from "../../interfaces/treasury/ITreasuryVotingPower.sol";
import { LibTreasury } from "../LibTreasury.sol";
import { ITreasury } from "../../interfaces/treasury/ITreasury.sol";

library LibTreasuryVotingPower {

  function _increaseVotingPower(address voter, uint amount) internal {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    require(msg.sender == tvp.votingPowerManager);
    // increase totalVotingPower
    tvp.totalAmountOfVotingPower += amount;
    // increase voter voting power
    tvp.votingPower[voter] += amount;
  }

  function _decreaseVotingPower(address voter, uint amount) internal {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    require(msg.sender == tvp.votingPowerManager);
    require(!_hasVotedInActiveProposals(voter), "Cannot unstake until proposal is active");
    // decrease totalVotingPower
    tvp.totalAmountOfVotingPower -= amount;
    // decrease voter voting power
    tvp.votingPower[voter] -= amount;
  }
// this function is under the question maybe moved
  function _hasVotedInActiveProposals(address voter) internal view returns(bool) {
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

  function _getVoterVotingPower(address voter) internal view returns(uint) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.votingPower[voter];
  }

  function _getTotalAmountOfVotingPower() internal view returns(uint) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.totalAmountOfVotingPower;
  }

  function _getMinimumQuorum() internal view returns(uint) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.minimumQuorum;
  }

  function _isQuorum() internal view returns(bool) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.minimumQuorum >= tvp.totalAmountOfVotingPower;
  }

  function _isEnoughVotingPower(address holder) internal view returns(bool) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    uint voterPower = _getVoterVotingPower(holder);
    return voterPower >= (uint(tvp.thresholdForInitiator) * tvp.totalAmountOfVotingPower / uint(tvp.precision));
  }

  function _isProposalThresholdReached(uint amountOfVotes) internal view returns(bool) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return amountOfVotes >= (tvp.thresholdForProposal * tvp.totalAmountOfVotingPower / uint(tvp.precision));
  }
}
