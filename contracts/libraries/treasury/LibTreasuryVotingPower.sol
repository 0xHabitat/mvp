// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// looks like i don't need this
// i can just request data for treasury or all other management system
// and after that calculate everything and write data (proposal) back to this ms
import {ITreasuryVotingPower} from "../../interfaces/treasury/ITreasuryVotingPower.sol";
import {LibTreasury} from "../LibTreasury.sol";
import {LibVotingPower} from "../decisionSystem/votingPower/LibVotingPower.sol";

library LibTreasuryVotingPower {
  function _getMinimumQuorum() internal view returns (uint256) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    uint256 maxAmountOfVotingPower = LibVotingPower._getMaxAmountOfVotingPower();
    return (uint256(tvp.minimumQuorum) * maxAmountOfVotingPower) / uint256(tvp.precision);
  }

  function _isQuorum() internal view returns (bool) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    uint256 maxAmountOfVotingPower = LibVotingPower._getMaxAmountOfVotingPower();
    uint256 totalAmountOfVotingPower = LibVotingPower._getTotalAmountOfVotingPower();
    return
      (uint256(tvp.minimumQuorum) * maxAmountOfVotingPower) / uint256(tvp.precision) <=
      totalAmountOfVotingPower;
  }

  function _isEnoughVotingPower(address holder) internal view returns (bool) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    uint256 voterPower = LibVotingPower._getVoterVotingPower(holder);
    uint256 totalAmountOfVotingPower = LibVotingPower._getTotalAmountOfVotingPower();
    return
      voterPower >=
      ((uint256(tvp.thresholdForInitiator) * totalAmountOfVotingPower) / uint256(tvp.precision));
  }

  function _isProposalThresholdReached(uint256 amountOfVotes) internal view returns (bool) {
    ITreasuryVotingPower.TreasuryVotingPower storage tvp = LibTreasury._getTreasuryVotingPower();
    uint256 totalAmountOfVotingPower = LibVotingPower._getTotalAmountOfVotingPower();
    return
      amountOfVotes >=
      ((uint256(tvp.thresholdForProposal) * totalAmountOfVotingPower) / uint256(tvp.precision));
  }
}
