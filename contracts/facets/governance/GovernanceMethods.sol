// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibHabitatDiamond} from "../../libraries/LibHabitatDiamond.sol";
import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibDecisionSystemSpecificData} from "../../libraries/decisionSystem/LibDecisionSystemSpecificData.sol";

/**
 * @title GovernanceMethods - Contract contains functions that implement governance module actions.
 * @dev TODO add events
 * @dev TODO change dao meta data
 * @author @roleengineer
 */
contract GovernanceMethods {
  /**
   * @notice Governance action - UpdateFacet. Allows to update facet.
   * @dev New facet address must be registered by AddressesProvider.
   *      All old facet function selectors are replaced by new one.
   * @param newFacetAddress The new facet address that replace old facet address.
   */
  function updateFacet(address newFacetAddress) external {
    LibHabitatDiamond.updateFacet(newFacetAddress);
  }

   /**
    * @notice Governance action - UpdateFacetAndState. Allows to update facet and state.
    * @dev New facet address must be registered by AddressesProvider. AddressesProvider
    *       must have init contract for a new facet.
    * @param newFacetAddress The new facet address that replace old facet address.
    * @param stateUpdate Encoded calldata (with selector) for a init contract function.
    */
  function updateFacetAndState(address newFacetAddress, bytes memory stateUpdate) external {
    LibHabitatDiamond.updateFacetAndState(newFacetAddress, stateUpdate);
  }

  /**
   * @notice Governance action - ChangeDecisionData. Allows to completely change
   *         `msName` module specific decision data stored inside the DAO for
   *          decision type `decisionType`.
   * @param msName Module name, which decision data should be changed.
   * @param decisionType Decision system type, which specific data should be changed.
   * @param newDecisionData Encoded specific decision data `decisionType` struct.
   */
  function changeDecisionData(
    string memory msName,
    uint8 decisionType,
    bytes memory newDecisionData
  ) external {
    LibManagementSystem._setMSSpecificDataForDecisionType(
      msName,
      IManagementSystem.DecisionType(decisionType),
      newDecisionData
    );
  }

  /**
   * @notice Governance action - ChangeThresholdForInitiator. Allows to change
   *         `msName` module threshold for initiator value (part of Voting Power Specific Data).
   * @param msName Module name, which threshold for initiator value should be changed.
   * @param newThresholdForInitiator Value of new threshold for initiator (consider DAO precision to convert from percentage).
   */
  function changeThresholdForInitiator(
    string memory msName,
    uint256 newThresholdForInitiator
  ) external {
    bytes memory newVPSD = LibDecisionSystemSpecificData._changedThresholdForInitiatorBytes(
      msName,
      newThresholdForInitiator
    );
    LibManagementSystem._setMSSpecificDataForDecisionType(
      msName,
      IManagementSystem.DecisionType(2),
      newVPSD
    );
  }

  /**
   * @notice Governance action - ChangeThresholdForProposal. Allows to change
   *         `msName` module threshold for proposal value (part of Voting Power Specific Data struct).
   * @param msName Module name, which threshold for proposal value should be changed.
   * @param newThresholdForProposal Value of new threshold for proposal (consider DAO precision to convert from percentage).
   */
  function changeThresholdForProposal(
    string memory msName,
    uint256 newThresholdForProposal
  ) external {
    bytes memory newVPSD = LibDecisionSystemSpecificData._changedThresholdForProposalBytes(
      msName,
      newThresholdForProposal
    );
    LibManagementSystem._setMSSpecificDataForDecisionType(
      msName,
      IManagementSystem.DecisionType(2),
      newVPSD
    );
  }

  /**
   * @notice Governance action - ChangeSecondsProposalVotingPeriod. Allows to change
   *         `msName` module seconds proposal voting period value (part of Voting Power Specific Data struct).
   * @param msName Module name, which proposal voting period value should be changed.
   * @param newSecondsProposalVotingPeriod Value of new proposal voting period in seconds.
   */
  function changeSecondsProposalVotingPeriod(
    string memory msName,
    uint256 newSecondsProposalVotingPeriod
  ) external {
    bytes memory newVPSD = LibDecisionSystemSpecificData._changedSecondsProposalVotingPeriodBytes(
      msName,
      newSecondsProposalVotingPeriod
    );
    LibManagementSystem._setMSSpecificDataForDecisionType(
      msName,
      IManagementSystem.DecisionType(2),
      newVPSD
    );
  }

  /**
   * @notice Governance action - ChangeSecondsProposalExecutionDelayPeriodVP. Allows to change
   *         `msName` module seconds proposal execution delay period value (part of Voting Power Specific Data struct).
   * @param msName Module name, which proposal execution delay period value should be changed.
   * @param newSecondsProposalExecutionDelayPeriodVP Value of new proposal execution delay period in seconds.
   */
  function changeSecondsProposalExecutionDelayPeriodVP(
    string memory msName,
    uint256 newSecondsProposalExecutionDelayPeriodVP
  ) external {
    bytes memory newVPSD = LibDecisionSystemSpecificData
      ._changedSecondsProposalExecutionDelayPeriodVPBytes(
        msName,
        newSecondsProposalExecutionDelayPeriodVP
      );
    LibManagementSystem._setMSSpecificDataForDecisionType(
      msName,
      IManagementSystem.DecisionType(2),
      newVPSD
    );
  }

  /**
   * @notice Governance action - ChangeSecondsProposalExecutionDelayPeriodSigners. Allows to change
   *         `msName` module seconds proposal execution delay period value (part of Signers Specific Data struct).
   * @param msName Module name, which proposal execution delay period value should be changed.
   * @param newSecondsProposalExecutionDelayPeriodSigners Value of new proposal execution delay period in seconds.
   */
  function changeSecondsProposalExecutionDelayPeriodSigners(
    string memory msName,
    uint256 newSecondsProposalExecutionDelayPeriodSigners
  ) external {
    bytes memory newSSD = LibDecisionSystemSpecificData
      ._changedSecondsProposalExecutionDelayPeriodSignersBytes(
        msName,
        newSecondsProposalExecutionDelayPeriodSigners
      );
    LibManagementSystem._setMSSpecificDataForDecisionType(
      msName,
      IManagementSystem.DecisionType(3),
      newSSD
    );
  }
}
