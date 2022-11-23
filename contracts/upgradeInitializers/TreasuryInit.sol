// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../libraries/dao/LibManagementSystem.sol";
import {IManagementSystem} from "../interfaces/dao/IManagementSystem.sol";

contract TreasuryInit {
  // voting power
  function initTreasuryVotingPowerSpecificData(
    uint64 thresholdForInitiator,
    uint64 thresholdForProposal,
    uint64 secondsProposalVotingPeriod,
    uint64 secondsProposalExecutionDelayPeriod
  ) public {
    IManagementSystem.MSData storage msData = LibManagementSystem._getMSDataByName("treasury");
    bytes memory specificDataVotingPower = abi.encode(
      thresholdForInitiator,
      thresholdForProposal,
      secondsProposalVotingPeriod,
      secondsProposalExecutionDelayPeriod
    );
    msData.decisionSpecificData[IManagementSystem.DecisionType(2)] = specificDataVotingPower;
  }

  // signers
  function initTreasurySignersSpecificData(
    uint256 secondsProposalExecutionDelayPeriod
  ) public {
    IManagementSystem.MSData storage msData = LibManagementSystem._getMSDataByName("treasury");
    bytes memory specificDataSigners = abi.encode(
      secondsProposalExecutionDelayPeriod
    );
    msData.decisionSpecificData[IManagementSystem.DecisionType(3)] = specificDataSigners;
  }

  function initTreasuryVotingPowerAndSignersSpecificData(
    bytes memory treasuryVotingPowerSpecificData,
    bytes memory treasurySignersSpecificData
  ) external {
    (
      uint64 thresholdForInitiator,
      uint64 thresholdForProposal,
      uint64 secondsProposalVotingPeriod,
      uint64 secondsProposalExecutionDelayPeriod
    ) = abi.decode(treasuryVotingPowerSpecificData, (uint64,uint64,uint64,uint64));
    initTreasuryVotingPowerSpecificData(
      thresholdForInitiator,
      thresholdForProposal,
      secondsProposalVotingPeriod,
      secondsProposalExecutionDelayPeriod
    );
    (uint secondsDelaySigners) = abi.decode(treasurySignersSpecificData, (uint256));
    initTreasurySignersSpecificData(secondsDelaySigners);
  }
}
