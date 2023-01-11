// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibHabitatDiamond} from "../../libraries/LibHabitatDiamond.sol";
import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibDecisionSystemSpecificData} from "../../libraries/decisionSystem/LibDecisionSystemSpecificData.sol";

// TODO add events
contract GovernanceMethods {
  // Governance actions
  function updateFacet(address newFacetAddress) external {
    LibHabitatDiamond.updateFacet(newFacetAddress);
  }

  function updateFacetAndState(address newFacetAddress, bytes memory stateUpdate) external {
    LibHabitatDiamond.updateFacetAndState(newFacetAddress, stateUpdate);
  }

  function changeDecisionData(string memory msName, uint8 decisionType, bytes memory newDecisionData) external {
    LibManagementSystem._setMSSpecificDataForDecisionType(msName, IManagementSystem.DecisionType(decisionType), newDecisionData);
  }

  function changeThresholdForInitiator(string memory msName, uint256 newThresholdForInitiator) external {
    bytes memory newVPSD = LibDecisionSystemSpecificData._changedThresholdForInitiatorBytes(msName,newThresholdForInitiator);
    LibManagementSystem._setMSSpecificDataForDecisionType(msName, IManagementSystem.DecisionType(2), newVPSD);
  }

  function changeThresholdForProposal(string memory msName, uint256 newThresholdForProposal) external {
    bytes memory newVPSD = LibDecisionSystemSpecificData._changedThresholdForProposalBytes(msName,newThresholdForProposal);
    LibManagementSystem._setMSSpecificDataForDecisionType(msName, IManagementSystem.DecisionType(2), newVPSD);
  }

  function changeSecondsProposalVotingPeriod(string memory msName, uint256 newSecondsProposalVotingPeriod) external {
    bytes memory newVPSD = LibDecisionSystemSpecificData._changedSecondsProposalVotingPeriodBytes(msName,newSecondsProposalVotingPeriod);
    LibManagementSystem._setMSSpecificDataForDecisionType(msName, IManagementSystem.DecisionType(2), newVPSD);
  }

  function changeSecondsProposalExecutionDelayPeriodVP(string memory msName, uint256 newSecondsProposalExecutionDelayPeriodVP) external {
    bytes memory newVPSD = LibDecisionSystemSpecificData._changedSecondsProposalExecutionDelayPeriodVPBytes(msName,newSecondsProposalExecutionDelayPeriodVP);
    LibManagementSystem._setMSSpecificDataForDecisionType(msName, IManagementSystem.DecisionType(2), newVPSD);
  }

  function changeSecondsProposalExecutionDelayPeriodSigners(string memory msName, uint256 newSecondsProposalExecutionDelayPeriodSigners) external {
    bytes memory newSSD = LibDecisionSystemSpecificData._changedSecondsProposalExecutionDelayPeriodVPBytes(msName,newSecondsProposalExecutionDelayPeriodSigners);
    LibManagementSystem._setMSSpecificDataForDecisionType(msName, IManagementSystem.DecisionType(3), newSSD);
  }

  // TODO change dao meta data

}
