// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibTreasury} from "../libraries/LibTreasury.sol";
import {ITreasury} from "../interfaces/treasury/ITreasury.sol";
import {ITreasuryVotingPower} from "../interfaces/treasury/ITreasuryVotingPower.sol";

contract TreasuryInit {
    // default type
    function initTreasuryType0(
      uint128 _maxDuration,
      uint64 _minimumQuorum,
      uint64 _thresholdForProposal,
      uint64 _thresholdForInitiator,
      uint64 _precision,
      uint256 _proposalDelayTime
    ) external {
      ITreasury.Treasury storage ts = LibTreasury.treasuryStorage();
      ts.votingType = ITreasury.VotingType(0);
      ts.maxDuration = _maxDuration;
      ts.proposalDelayTime = _proposalDelayTime;
      ITreasuryVotingPower.TreasuryVotingPower storage tv = LibTreasury._getTreasuryVotingPower();

    tv.minimumQuorum = _minimumQuorum;
    tv.thresholdForProposal = _thresholdForProposal;
    tv.thresholdForInitiator = _thresholdForInitiator;
    tv.precision = _precision;
  }

  // signers
  function initTreasuryType1() external {
    ITreasury.Treasury storage ts = LibTreasury.treasuryStorage();
    ts.votingType = ITreasury.VotingType(1);
  }
}
