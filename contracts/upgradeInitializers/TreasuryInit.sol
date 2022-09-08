// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../libraries/dao/LibManagementSystem.sol";
import {IManagementSystem} from "../interfaces/dao/IManagementSystem.sol";

contract TreasuryInit {
    // default type
  function initTreasuryVotingPower(
    uint64 thresholdForInitiator,
    uint64 thresholdForProposal,
    uint64 secondsProposalVotingPeriod,
    uint64 secondsProposalExecutionDelayPeriod
  ) external {
    IManagementSystem.MSData storage msData = LibManagementSystem._getMSDataByName("treasury");
    bytes memory specificVotingPowerData = abi.encode(
      thresholdForInitiator,
      thresholdForProposal,
      secondsProposalVotingPeriod,
      secondsProposalExecutionDelayPeriod
    );
    msData.decisionSpecificData[IManagementSystem.DecisionType(2)] = specificVotingPowerData;
  }

  // signers
  function initTreasurySigners() external {
  }
}
