// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {LibDecisionProcess} from "../../libraries/decisionSystem/LibDecisionProcess.sol";

contract GovernanceFacet {
  enum GovernanceAction {
    None,
    UpdateFacet,
    UpdateFacetAndState,
    ChangeDecisionData,
    ChangeThresholdForInitiator,
    ChangeThresholdForProposal,
    ChangeSecondsProposalVotingPeriod,
    ChangeSecondsProposalExecutionDelayPeriodVP,
    ChangeSecondsProposalExecutionDelayPeriodSigners
    // Change value/values
  }

  address immutable governanceMethods;

  constructor(address _governanceMethods) {
    governanceMethods = _governanceMethods;
  }

  function getGovernanceMethods() external view returns (address) {
    return governanceMethods;
  }

  function createGovernanceProposal(
    GovernanceAction governanceAction,
    bytes memory callData
  ) public returns (uint256 proposalId) {
    bytes memory validCallData;
    if (governanceAction == GovernanceAction.UpdateFacet) {
      address newFacetAddress = abi.decode(callData, (address));
      bytes4 updateFacet = bytes4(keccak256(bytes("updateFacet(address)")));
      validCallData = abi.encodeWithSelector(updateFacet, newFacetAddress);
    } else if (governanceAction == GovernanceAction.UpdateFacetAndState) {
      (address newFacetAddress, bytes memory stateUpdate) = abi.decode(callData, (address, bytes));
      bytes4 updateFacetAndState = bytes4(keccak256(bytes("updateFacetAndState(address,bytes)")));
      validCallData = abi.encodeWithSelector(updateFacetAndState, newFacetAddress, stateUpdate);
    } else if (governanceAction == GovernanceAction.ChangeDecisionData) {
      (string memory msName, uint8 decisionType, bytes memory newDecisionData) = abi.decode(
        callData,
        (string, uint8, bytes)
      );
      bytes4 changeDecisionData = bytes4(
        keccak256(bytes("changeDecisionData(string,uint8,bytes)"))
      );
      validCallData = abi.encodeWithSelector(
        changeDecisionData,
        msName,
        decisionType,
        newDecisionData
      );
    } else if (governanceAction == GovernanceAction.ChangeThresholdForInitiator) {
      validCallData = _changeUintInDecisionData(callData, "ThresholdForInitiator");
    } else if (governanceAction == GovernanceAction.ChangeThresholdForProposal) {
      validCallData = _changeUintInDecisionData(callData, "ThresholdForProposal");
    } else if (governanceAction == GovernanceAction.ChangeSecondsProposalVotingPeriod) {
      validCallData = _changeUintInDecisionData(callData, "SecondsProposalVotingPeriod");
    } else if (governanceAction == GovernanceAction.ChangeSecondsProposalExecutionDelayPeriodVP) {
      validCallData = _changeUintInDecisionData(callData, "SecondsProposalExecutionDelayPeriodVP");
    } else if (
      governanceAction == GovernanceAction.ChangeSecondsProposalExecutionDelayPeriodSigners
    ) {
      validCallData = _changeUintInDecisionData(
        callData,
        "SecondsProposalExecutionDelayPeriodSigners"
      );
    } else {
      revert("No valid governance action was requested.");
    }
    proposalId = LibDecisionProcess.createProposal(
      "governance",
      governanceMethods,
      0,
      validCallData
    );
  }

  function decideOnGovernanceProposal(uint256 proposalId, bool decision) public {
    LibDecisionProcess.decideOnProposal("governance", proposalId, decision);
  }

  function acceptOrRejectGovernanceProposal(uint256 proposalId) public {
    LibDecisionProcess.acceptOrRejectProposal("governance", proposalId);
  }

  function executeGovernanceProposal(uint256 proposalId) public returns (bool result) {
    bytes4 thisSelector = bytes4(keccak256(bytes("executeGovernanceProposal(uint256)")));
    result = LibDecisionProcess.executeProposalDelegateCall("governance", proposalId, thisSelector);
  }

  // few wrappers

  function updateFacetInitProposal(address newFacetAddress) public returns (uint256 proposalId) {
    bytes memory callData = abi.encode(newFacetAddress);
    proposalId = createGovernanceProposal(GovernanceAction.UpdateFacet, callData);
  }

  function updateFacetAndStateInitProposal(
    address newFacetAddress,
    bytes memory stateUpdate
  ) public returns (uint256 proposalId) {
    bytes memory callData = abi.encode(newFacetAddress, stateUpdate);
    proposalId = createGovernanceProposal(GovernanceAction.UpdateFacetAndState, callData);
  }

  // batch for direct caller
  function batchedGovernanceProposalExecution(
    GovernanceAction governanceAction,
    bytes memory callData
  ) public returns (bool result) {
    uint256 proposalId = createGovernanceProposal(governanceAction, callData);
    acceptOrRejectGovernanceProposal(proposalId);
    result = executeGovernanceProposal(proposalId);
  }

  function updateFacetBatchedExecution(address newFacetAddress) public returns (bool result) {
    uint256 proposalId = updateFacetInitProposal(newFacetAddress);
    acceptOrRejectGovernanceProposal(proposalId);
    result = executeGovernanceProposal(proposalId);
  }

  function updateFacetAndStateBatchedExecution(
    address newFacetAddress,
    bytes memory stateUpdate
  ) public returns (bool result) {
    uint256 proposalId = updateFacetAndStateInitProposal(newFacetAddress, stateUpdate);
    acceptOrRejectGovernanceProposal(proposalId);
    result = executeGovernanceProposal(proposalId);
  }

  // MULTI PROPOSALS
  function createSeveralGovernanceProposals(
    GovernanceAction[] calldata governanceActions,
    bytes[] calldata callDatas
  ) external returns (uint256[] memory) {
    uint256 numberOfProposals = governanceActions.length;
    require(callDatas.length == numberOfProposals, "Different array length");
    uint256[] memory proposalIds = new uint256[](numberOfProposals);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      proposalIds[i] = createGovernanceProposal(governanceActions[i], callDatas[i]);
    }
    return proposalIds;
  }

  function decideOnSeveralGovernanceProposals(
    uint256[] calldata proposalsIds,
    bool[] calldata decisions
  ) external {
    require(proposalsIds.length == decisions.length, "Different array length");
    for (uint256 i = 0; i < proposalsIds.length; i++) {
      decideOnGovernanceProposal(proposalsIds[i], decisions[i]);
    }
  }

  function acceptOrRejectSeveralGovernanceProposals(uint256[] calldata proposalIds) external {
    for (uint256 i = 0; i < proposalIds.length; i++) {
      acceptOrRejectGovernanceProposal(proposalIds[i]);
    }
  }

  function executeSeveralGovernanceProposals(
    uint256[] memory proposalIds
  ) external returns (bool[] memory results) {
    results = new bool[](proposalIds.length);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      results[i] = executeGovernanceProposal(proposalIds[i]);
    }
  }

  // helper function
  function _changeUintInDecisionData(
    bytes memory callData,
    string memory uintName
  ) internal pure returns (bytes memory validCallData) {
    (string memory msName, uint256 newValue) = abi.decode(callData, (string, uint256));
    string memory funcSig = string(abi.encodePacked("change", uintName, "(string,uint256)"));
    bytes4 funcSelector = bytes4(keccak256(bytes(funcSig)));
    validCallData = abi.encodeWithSelector(funcSelector, msName, newValue);
  }
}
