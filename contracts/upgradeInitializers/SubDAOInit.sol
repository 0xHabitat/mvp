// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { LibTreasury } from "../libraries/LibTreasury.sol";
import { ITreasury } from "../interfaces/treasury/ITreasury.sol";
import { ITreasuryVotingPower } from "../interfaces/treasury/ITreasuryVotingPower.sol";
import { SubDAOContract0 } from "../templates/SubDAOContract.sol";

contract SubDAOInit {
    // default type
    function initSubDAOType0(
      uint128 _amountOfKeys,
      uint128 _thresholdForProposal,
      address[] _keyHolders,
    ) external returns(address) {
      ITreasury.Treasury storage ts = LibTreasury.treasuryStorage();
      ts.votingType = ITreasury.VotingType(0);
      ts.maxDuration = _maxDuration;
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
