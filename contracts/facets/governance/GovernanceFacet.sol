// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {LibDecisionProcess} from "../../libraries/decisionSystem/LibDecisionProcess.sol";

/**
 * @title GovernanceFacet - Facet provides functions that handles interactions
 *                         with the DAO governance module.
 * @notice Governance module allows to change some DAO storage values (like decision
 *         systems specific data) and make controlled (through trusted source) updates.
 * @author @roleengineer
 */
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

  /**
   * @notice Returns contract address, which includes implementation of governance actions.
   */
  function getGovernanceMethods() external view returns (address) {
    return governanceMethods;
  }

  /**
   * @notice Method creates governance proposal.
   * @param governanceAction One of governance actions from a strict set.
   * @param callData Data payload (without selector) for a function from `governanceMethods` related to a chosen action.
   * @return proposalId Newly created governance proposal id.
   */
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

  /**
   * @notice Allows to decide on governance proposal.
   * @param proposalId The id of governance proposal to decide on.
   * @param decision True - for proposal, false - against proposal.
   */
  function decideOnGovernanceProposal(uint256 proposalId, bool decision) public {
    LibDecisionProcess.decideOnProposal("governance", proposalId, decision);
  }

  /**
   * @notice Allows to accept/reject governance proposal. Should be called when
   *         decision considered to be done based on rules of governance current decision type.
   * @param proposalId The id of governance proposal to accept/reject.
   */
  function acceptOrRejectGovernanceProposal(uint256 proposalId) public {
    LibDecisionProcess.acceptOrRejectProposal("governance", proposalId);
  }

  /**
   * @notice Allows to execute governance accepted proposal. Should be called at
   *         proposal execution timestamp.
   * @param proposalId The id of governance proposal to execute.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function executeGovernanceProposal(uint256 proposalId) public returns (bool result) {
    bytes4 thisSelector = bytes4(keccak256(bytes("executeGovernanceProposal(uint256)")));
    result = LibDecisionProcess.executeProposalDelegateCall("governance", proposalId, thisSelector);
  }

  /*//////////////////////////////////////////////////////////////
                    WRAPPER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Allows to init governance proposal to update facet.
   * @param newFacetAddress The new facet address that replace old facet address.
   * @return proposalId Newly created governance proposal id.
   */
  function updateFacetInitProposal(address newFacetAddress) public returns (uint256 proposalId) {
    bytes memory callData = abi.encode(newFacetAddress);
    proposalId = createGovernanceProposal(GovernanceAction.UpdateFacet, callData);
  }

  /**
   * @notice Allows to init governance proposal to update facet and state.
   * @param newFacetAddress The new facet address that replace old facet address.
   * @param stateUpdate Encoded calldata (with selector) for a init contract function.
   * @return proposalId Newly created governance proposal id.
   */
  function updateFacetAndStateInitProposal(
    address newFacetAddress,
    bytes memory stateUpdate
  ) public returns (uint256 proposalId) {
    bytes memory callData = abi.encode(newFacetAddress, stateUpdate);
    proposalId = createGovernanceProposal(GovernanceAction.UpdateFacetAndState, callData);
  }

  /*//////////////////////////////////////////////////////////////
                BATCHED FUNCTIONS FOR DIRECT CALLER
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Allows direct caller to create/accept/execute governance proposal in one call.
   * @param governanceAction One of governance actions from a strict set.
   * @param callData Data payload (without selector) for a function from `governanceMethods` related to a chosen action.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function batchedGovernanceProposalExecution(
    GovernanceAction governanceAction,
    bytes memory callData
  ) public returns (bool result) {
    uint256 proposalId = createGovernanceProposal(governanceAction, callData);
    acceptOrRejectGovernanceProposal(proposalId);
    result = executeGovernanceProposal(proposalId);
  }

  /**
   * @notice Allows direct caller to create/accept/execute governance proposal
   *         to update facet in one call.
   * @param newFacetAddress The new facet address that replace old facet address.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function updateFacetBatchedExecution(address newFacetAddress) public returns (bool result) {
    uint256 proposalId = updateFacetInitProposal(newFacetAddress);
    acceptOrRejectGovernanceProposal(proposalId);
    result = executeGovernanceProposal(proposalId);
  }

  /**
   * @notice Allows direct caller to create/accept/execute governance proposal
   *         to update facet and state in one call.
   * @param newFacetAddress The new facet address that replace old facet address.
   * @param stateUpdate Encoded calldata (with selector) for an init contract function.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function updateFacetAndStateBatchedExecution(
    address newFacetAddress,
    bytes memory stateUpdate
  ) public returns (bool result) {
    uint256 proposalId = updateFacetAndStateInitProposal(newFacetAddress, stateUpdate);
    acceptOrRejectGovernanceProposal(proposalId);
    result = executeGovernanceProposal(proposalId);
  }

  /*//////////////////////////////////////////////////////////////
                    MULTI PROPOSALS FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Method creates several governance proposals.
   * @param governanceActions An array of governance actions from a strict set.
   * @param callDatas An array of data payload (without selector) for a function from `governanceMethods` related to a chosen action.
   * @return An array of newly created governance proposal ids.
   */
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

  /**
   * @notice Allows to decide on several governance proposals.
   * @param proposalIds An array of governance proposal ids to decide on.
   * @param decisions An array of booleans: True - for proposal, false - against proposal.
   */
  function decideOnSeveralGovernanceProposals(
    uint256[] calldata proposalIds,
    bool[] calldata decisions
  ) external {
    require(proposalIds.length == decisions.length, "Different array length");
    for (uint256 i = 0; i < proposalIds.length; i++) {
      decideOnGovernanceProposal(proposalIds[i], decisions[i]);
    }
  }

  /**
   * @notice Allows to accept/reject several governance proposals. Should be called when
   *         decisions considered to be done based on rules of governance current decision type.
   * @param proposalIds An array of governance proposal ids to accept/reject.
   */
  function acceptOrRejectSeveralGovernanceProposals(uint256[] calldata proposalIds) external {
    for (uint256 i = 0; i < proposalIds.length; i++) {
      acceptOrRejectGovernanceProposal(proposalIds[i]);
    }
  }

  /**
   * @notice Allows to execute several governance accepted proposals. Should be
   *         called at/after proposals execution timestamp.
   * @param proposalIds An array of governance proposal ids to execute.
   * @return results An array of the proposal execution results: false if during execution call revert poped up.
   */
  function executeSeveralGovernanceProposals(
    uint256[] memory proposalIds
  ) external returns (bool[] memory results) {
    results = new bool[](proposalIds.length);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      results[i] = executeGovernanceProposal(proposalIds[i]);
    }
  }

  /**
   * @dev Helps to compile calldata for a governance methods with the same pattern.
   */
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
