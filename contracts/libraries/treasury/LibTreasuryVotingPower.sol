// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { ITreasuryVotingPower } from "../../interfaces/treasury/ITreasuryVotingPower.sol";
import { LibTreasury } from "../LibTreasury.sol";
import { LibVotingPower } from "../LibVotingPower.sol";

library LibTreasuryVotingPower {

  function _getMinimumQuorum() internal view returns(uint) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    uint maxAmountOfVotingPower = LibVotingPower._getMaxAmountOfVotingPower();
    return uint(tvp.minimumQuorum) * maxAmountOfVotingPower / uint(tvp.precision);
  }

  function _isQuorum() internal view returns(bool) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    uint maxAmountOfVotingPower = LibVotingPower._getMaxAmountOfVotingPower();
    uint totalAmountOfVotingPower = LibVotingPower._getTotalAmountOfVotingPower();
    return uint(tvp.minimumQuorum) * maxAmountOfVotingPower / uint(tvp.precision) <= totalAmountOfVotingPower;
  }

  function _isEnoughVotingPower(address holder) internal view returns(bool) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    uint voterPower = LibVotingPower._getVoterVotingPower(holder);
    uint totalAmountOfVotingPower = LibVotingPower._getTotalAmountOfVotingPower();
    return voterPower >= (uint(tvp.thresholdForInitiator) * totalAmountOfVotingPower / uint(tvp.precision));
  }

  function _isProposalThresholdReached(uint amountOfVotes) internal view returns(bool) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    uint totalAmountOfVotingPower = LibVotingPower._getTotalAmountOfVotingPower();
    return amountOfVotes >= (uint(tvp.thresholdForProposal) * totalAmountOfVotingPower / uint(tvp.precision));
  }
}
