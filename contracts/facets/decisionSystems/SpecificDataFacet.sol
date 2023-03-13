// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDecisionSystemSpecificData} from "../../libraries/decisionSystem/LibDecisionSystemSpecificData.sol";
import {VotingPowerSpecificData, SignerSpecificData} from "../../interfaces/decisionSystem/SpecificDataStructs.sol";

/**
 * @title SpecificDataFacet - Facet provides view functions related to the decision
 *                         systems specific data stored inside the DAO.
 * @author @roleengineer
 */
contract SpecificDataFacet {
  /**
   * @notice Returns `msName` module threshold for proposal numerator.
   * @dev Voting Power Decision System specific data.
   * @param msName Module name, which threshold is requested.
   */
  function thresholdForProposalNumerator(string memory msName) external view returns (uint256) {
    return LibDecisionSystemSpecificData._getThresholdForProposalNumerator(msName);
  }

  /**
   * @notice Returns `msName` module threshold for initiator numerator.
   * @dev Voting Power Decision System specific data.
   * @param msName Module name, which threshold is requested.
   */
  function thresholdForInitiatorNumerator(string memory msName) external view returns (uint256) {
    return LibDecisionSystemSpecificData._getThresholdForInitiatorNumerator(msName);
  }

  /**
   * @notice Returns `msName` module seconds proposal voting period.
   * @dev Voting Power Decision System specific data.
   * @param msName Module name, which voting period is requested.
   */
  function getSecondsProposalVotingPeriod(string memory msName) external view returns (uint256) {
    return LibDecisionSystemSpecificData._getSecondsProposalVotingPeriod(msName);
  }

  /**
   * @notice Returns `msName` module seconds proposal execution delay period.
   * @dev Voting Power Decision System specific data.
   * @param msName Module name, which execution delay period is requested.
   */
  function getSecondsProposalExecutionDelayPeriodVP(
    string memory msName
  ) external view returns (uint256) {
    return LibDecisionSystemSpecificData._getSecondsProposalExecutionDelayPeriodVP(msName);
  }

  /**
   * @notice Returns `msName` module seconds proposal execution delay period.
   * @dev Signers Decision System specific data.
   * @param msName Module name, which execution delay period is requested.
   */
  function getSecondsProposalExecutionDelayPeriodSigners(
    string memory msName
  ) external view returns (uint256) {
    return LibDecisionSystemSpecificData._getSecondsProposalExecutionDelayPeriodSigners(msName);
  }

  /**
   * @notice Returns `msName` module voting power specific data struct.
   * @param msName Module name, which voting power specific data is requested.
   */
  function getMSVotingPowerSpecificData(
    string memory msName
  ) external view returns (VotingPowerSpecificData memory vpsd) {
    return LibDecisionSystemSpecificData._getMSVotingPowerSpecificData(msName);
  }

  /**
   * @notice Returns `msName` module signers specific data struct.
   * @param msName Module name, which signers specific data is requested.
   */
  function getMSSignersSpecificData(
    string memory msName
  ) external view returns (SignerSpecificData memory ssd) {
    return LibDecisionSystemSpecificData._getMSSignersSpecificData(msName);
  }
}
