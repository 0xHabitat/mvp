// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../libraries/dao/LibManagementSystem.sol";
import {IManagementSystem} from "../interfaces/dao/IManagementSystem.sol";
// RENAME everywhere else
// initSignersSpecificData(msName[], data[])
// initVotingPowerSpecificData(msName[], data[])

contract SpecificDataInit {

  function initSpecificDataForDecisionType(
    IManagementSystem.DecisionType decisionType,
    string[] memory msNames,
    bytes[] memory specificDatas
  ) public {
    require(msNames.length == specificDatas.length, "Wrong input: different array length.");
    for (uint i = 0; i < msNames.length; i++) {
      LibManagementSystem._setMSSpecificDataForDecisionType(
        msNames[i],
        decisionType,
        specificDatas[i]
      );
    }
  }
  // voting power
  function initVotingPowerSpecificData(
    string[] memory msNames,
    uint256[] memory thresholdForInitiator,
    uint256[] memory thresholdForProposal,
    uint256[] memory secondsProposalVotingPeriod,
    uint256[] memory secondsProposalExecutionDelayPeriod
  ) public {
    uint msNumber = msNames.length;
    require(
      msNumber == thresholdForInitiator.length &&
      msNumber == thresholdForProposal.length &&
      msNumber == secondsProposalVotingPeriod.length &&
      msNumber == secondsProposalExecutionDelayPeriod.length,
      "Wrong input: different array length."
    );
    bytes[] memory specificDatas = new bytes[](msNumber);
    for (uint i = 0; i < msNumber; i++) {
      bytes memory specificDataVotingPower = abi.encode(
        thresholdForInitiator[i],
        thresholdForProposal[i],
        secondsProposalVotingPeriod[i],
        secondsProposalExecutionDelayPeriod[i]
      );
      specificDatas[i] = specificDataVotingPower;
    }
    initSpecificDataForDecisionType(
      IManagementSystem.DecisionType(2),
      msNames,
      specificDatas
    );
  }

  // signers
  function initSignersSpecificData(
    string[] memory msNames,
    uint256[] memory secondsProposalExecutionDelayPeriod
  ) public {
    require(msNames.length == secondsProposalExecutionDelayPeriod.length, "Wrong input: different array length.");
    bytes[] memory specificDatas = new bytes[](msNames.length);
    for (uint i = 0; i < msNames.length; i++) {
      bytes memory specificDataSigners = abi.encode(secondsProposalExecutionDelayPeriod);
      specificDatas[i] = specificDataSigners;
    }
    initSpecificDataForDecisionType(
      IManagementSystem.DecisionType(3),
      msNames,
      specificDatas
    );
  }

  function initVotingPowerAndSignersSpecificData(
    string[] memory msNames,
    bytes[] memory votingPowerSpecificDatas,
    bytes[] memory signersSpecificDatas
  ) external {
    require(
      msNames.length == votingPowerSpecificDatas.length &&
      msNames.length == signersSpecificDatas.length,
      "Wrong input: different array length."
    );

    initSpecificDataForDecisionType(
      IManagementSystem.DecisionType(2),
      msNames,
      votingPowerSpecificDatas
    );

    initSpecificDataForDecisionType(
      IManagementSystem.DecisionType(3),
      msNames,
      signersSpecificDatas
    );
  }

  function initVotingPowerAndSignersSpecificData(
    string[] memory msNames,
    uint256[] memory thresholdForInitiator,
    uint256[] memory thresholdForProposal,
    uint256[] memory secondsProposalVotingPeriod,
    uint256[] memory secondsProposalExecutionDelayPeriodVP,
    uint256[] memory secondsProposalExecutionDelayPeriodSigners
  ) external {
    initVotingPowerSpecificData(
      msNames,
      thresholdForInitiator,
      thresholdForProposal,
      secondsProposalVotingPeriod,
      secondsProposalExecutionDelayPeriodVP
    );
    initSignersSpecificData(msNames, secondsProposalExecutionDelayPeriodSigners);
  }

}
