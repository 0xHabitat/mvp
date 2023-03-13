// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../libraries/dao/LibManagementSystem.sol";
import {IManagementSystem} from "../interfaces/dao/IManagementSystem.sol";

/**
 * @title SpecificDataInit - Init contract that initialize the decision systems
 *                           specific data for each module.
 * @dev TODO RENAME everywhere else: initSignersSpecificData(msName[], data[]) initVotingPowerSpecificData(msName[], data[])
 * @author @roleengineer
 */
contract SpecificDataInit {
  /**
   * @notice Method initiates specific data of `decisionType` for each module in `msNames`.
   * @param decisionType Specific data of this decision type (uint8) should be set.
   * @param msNames An array of module names, which specificData for their `decisionType` decision type should be initialize.
   * @param specificDatas An array of encoded specific data.
   */
  function initSpecificDataForDecisionType(
    IManagementSystem.DecisionType decisionType,
    string[] memory msNames,
    bytes[] memory specificDatas
  ) public {
    require(msNames.length == specificDatas.length, "Wrong input: different array length.");
    for (uint256 i = 0; i < msNames.length; i++) {
      LibManagementSystem._setMSSpecificDataForDecisionType(
        msNames[i],
        decisionType,
        specificDatas[i]
      );
    }
  }

  /**
   * @notice Method initiates voting power specific data for each module in `msNames`.
   * @param msNames An array of module names, which voting power specific data should be initialize.
   * @param thresholdForInitiator Array of thresholds for initiator (consider DAO precision to convert from percentage).
   * @param thresholdForProposal Array of thresholds for proposal (consider DAO precision to convert from percentage).
   * @param secondsProposalVotingPeriod Array of proposal voting periods in seconds.
   * @param secondsProposalExecutionDelayPeriod Array of proposal execution delay periods in seconds.
   */
  function initVotingPowerSpecificData(
    string[] memory msNames,
    uint256[] memory thresholdForInitiator,
    uint256[] memory thresholdForProposal,
    uint256[] memory secondsProposalVotingPeriod,
    uint256[] memory secondsProposalExecutionDelayPeriod
  ) public {
    uint256 msNumber = msNames.length;
    require(
      msNumber == thresholdForInitiator.length &&
        msNumber == thresholdForProposal.length &&
        msNumber == secondsProposalVotingPeriod.length &&
        msNumber == secondsProposalExecutionDelayPeriod.length,
      "Wrong input: different array length."
    );
    bytes[] memory specificDatas = new bytes[](msNumber);
    for (uint256 i = 0; i < msNumber; i++) {
      bytes memory specificDataVotingPower = abi.encode(
        thresholdForInitiator[i],
        thresholdForProposal[i],
        secondsProposalVotingPeriod[i],
        secondsProposalExecutionDelayPeriod[i]
      );
      specificDatas[i] = specificDataVotingPower;
    }
    initSpecificDataForDecisionType(IManagementSystem.DecisionType(2), msNames, specificDatas);
  }

  /**
   * @notice Method initiates signers specific data for each module in `msNames`.
   * @param msNames An array of module names, which signers specific data should be initialize.
   * @param secondsProposalExecutionDelayPeriod Array of proposal execution delay periods in seconds.
   */
  function initSignersSpecificData(
    string[] memory msNames,
    uint256[] memory secondsProposalExecutionDelayPeriod
  ) public {
    require(
      msNames.length == secondsProposalExecutionDelayPeriod.length,
      "Wrong input: different array length."
    );
    bytes[] memory specificDatas = new bytes[](msNames.length);
    for (uint256 i = 0; i < msNames.length; i++) {
      bytes memory specificDataSigners = abi.encode(secondsProposalExecutionDelayPeriod);
      specificDatas[i] = specificDataSigners;
    }
    initSpecificDataForDecisionType(IManagementSystem.DecisionType(3), msNames, specificDatas);
  }

  /**
   * @notice Method initiates voting power and signers specific data for each module in `msNames`.
   * @param msNames An array of module names, which voting power and signers specific datas should be initialize.
   * @param votingPowerSpecificDatas Array of encoded voting power specific data.
   * @param signersSpecificDatas Array of encoded signers specific data.
   */
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

  /**
   * @notice Method initiates voting power and signers specific data for each module in `msNames`.
   * @param msNames An array of module names, which voting power and signers specific datas should be initialize.
   * @param thresholdForInitiator Array of thresholds for initiator (consider DAO precision to convert from percentage).
   * @param thresholdForProposal Array of thresholds for proposal (consider DAO precision to convert from percentage).
   * @param secondsProposalVotingPeriod Array of proposal voting periods in seconds.
   * @param secondsProposalExecutionDelayPeriodVP Array of proposal execution delay periods in seconds (voting power).
   * @param secondsProposalExecutionDelayPeriodSigners Array of proposal execution delay periods in seconds (signers).
   */
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
