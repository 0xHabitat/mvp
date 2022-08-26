// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../libraries/dao/LibManagementSystem.sol";
import {IManagementSystem} from "../interfaces/dao/IManagementSystem.sol";

contract TreasuryInit {
    // default type
  function initTreasuryVotingPower(
    uint64 minimumQuorum,
    uint64 thresholdForProposal,
    uint64 thresholdForInitiator,
    uint64 secondsProposalVotingPeriod,
    uint64 secondsProposalExecutionDelayPeriod
  ) external {
    IManagementSystem.MSData storage msData = LibManagementSystem._getMSDataByName("treasury");
    bytes memory specificVotingPowerData = abi.encode(
      minimumQuorum,
      thresholdForProposal,
      thresholdForInitiator,
      secondsProposalVotingPeriod,
      secondsProposalExecutionDelayPeriod
    );
    msData.decisionSpecificData[uint8(2)] = specificVotingPowerData;
  }

  // signers
  function initTreasurySigners() external {
  }
}
