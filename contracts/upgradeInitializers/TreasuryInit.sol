// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { LibTreasury } from "../libraries/LibTreasury.sol";
import { ITreasury } from "../interfaces/treasury/ITreasury.sol";
import { ITreasuryVotingPower } from "../interfaces/treasury/ITreasuryVotingPower.sol";
import { StakeContract } from "../external/VotingPowerManager.sol";

contract TreasuryInit {
    event VotingPowerManagerCreated(address indexed votingPowerManager, address indexed diamondAddress);
    // default type
    function initTreasuryType0(
      uint128 _maxDuration,
      uint _maxAmountOfVotingPower,
      uint64 _minimumQuorum,
      uint64 _thresholdForProposal,
      uint64 _thresholdForInitiator,
      uint64 _precision,
      bytes memory votingPowerManagerConstructor
    ) external {
      ITreasury.Treasury storage ts = LibTreasury.treasuryStorage();
      ts.votingType = ITreasury.VotingType(0);
      ts.maxDuration = _maxDuration;
      ITreasuryVotingPower.TreasuryVotingPower storage tv = LibTreasury._getTreasuryVotingPower();

      tv.maxAmountOfVotingPower = _maxAmountOfVotingPower;
      tv.minimumQuorum = _minimumQuorum;
      tv.thresholdForProposal = _thresholdForProposal;
      tv.thresholdForInitiator = _thresholdForInitiator;
      tv.precision = _precision;
      // we can even create new contract here, but need to check the gas cost of tx
      (uint _stakeContrPrecision, address[] memory _governanceTokens, uint256[] memory coefficients) = abi.decode(votingPowerManagerConstructor, (uint256, address[], uint256[]));
      StakeContract stakeContract = new StakeContract(address(this), _stakeContrPrecision, _governanceTokens, coefficients);
      tv.votingPowerManager = address(stakeContract);
      emit VotingPowerManagerCreated(address(stakeContract), address(this));
    }

    function initTreasuryType1() external {
      ITreasury.Treasury storage ts = LibTreasury.treasuryStorage();
      ts.votingType = ITreasury.VotingType(1);
    }
}
