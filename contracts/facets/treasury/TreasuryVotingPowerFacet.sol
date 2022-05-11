// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ITreasuryVotingPower} from "../../interfaces/treasury/ITreasuryVotingPower.sol";
import {LibTreasury} from "../../libraries/LibTreasury.sol";
import {LibTreasuryVotingPower} from "../../libraries/treasury/LibTreasuryVotingPower.sol";

contract TreasuryVotingPowerFacet is ITreasuryVotingPower {
  function minimumQuorumNumerator() external view override returns (uint64) {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.minimumQuorum;
  }

  function thresholdForProposalNumerator() external view override returns (uint64) {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.thresholdForProposal;
  }

  function thresholdForInitiatorNumerator() external view override returns (uint64) {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.thresholdForInitiator;
  }

  function treasuryDenominator() external view override returns (uint64) {
    TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    return tvp.precision;
  }

  function getMinimumQuorum() external view override returns (uint256) {
    return LibTreasuryVotingPower._getMinimumQuorum();
  }

  function isQourum() external view override returns (bool) {
    return LibTreasuryVotingPower._isQuorum();
  }

  function isEnoughVotingPower(address holder) external view override returns (bool) {
    return LibTreasuryVotingPower._isEnoughVotingPower(holder);
  }

  function isProposalThresholdReached(uint256 amountOfVotes) external view override returns (bool) {
    return LibTreasuryVotingPower._isProposalThresholdReached(amountOfVotes);
  }
}
