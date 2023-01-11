// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {IDiamondCut} from "../../interfaces/IDiamondCut.sol";
import {LibDecisionProcess} from "../../libraries/decisionSystem/LibDecisionProcess.sol";

contract ModuleManagerFacet {
  enum ModuleManagerAction {
    None,
    SwitchModuleDecider,
    AddNewModule,
    AddNewModuleAndStateUpdate,
    RemoveModule,
    ChangeAddressesProvider,
    DiamondCut
  }

  address immutable moduleManagerMethods;

  constructor(address _moduleManagerMethods) {
    moduleManagerMethods = _moduleManagerMethods;
  }

  function createModuleManagerProposal(
    ModuleManagerAction moduleManagerAction,
    bytes memory callData
  ) public  returns (uint256 proposalId) {
    bytes memory validCallData;
    if (moduleManagerAction == ModuleManagerAction.SwitchModuleDecider) {
      (string memory msName, address newDecider) = abi.decode(callData, (string,address));
      bytes4 switchModuleDecider = bytes4(keccak256(bytes("switchModuleDecider(string,address)")));
      validCallData = abi.encodeWithSelector(switchModuleDecider, msName, newDecider);
    } else if (moduleManagerAction == ModuleManagerAction.AddNewModule) {
      (
        string memory msName,
        uint8 decisionType,
        address deciderAddress,
        address[] memory facetAddresses,
        bytes4[][] memory facetSelectors
      ) = abi.decode(callData, (string,uint8,address,address[],bytes4[][]));
      bytes4 addNewManagementSystemWithFacets = bytes4(keccak256(bytes("addNewManagementSystemWithFacets(string,uint8,address,address[],bytes4[][])")));
      validCallData = abi.encodeWithSelector(
        addNewManagementSystemWithFacets,
        msName,
        decisionType,
        deciderAddress,
        facetAddresses,
        facetSelectors
      );
    } else if (moduleManagerAction == ModuleManagerAction.AddNewModuleAndStateUpdate) {
      (
        string memory msName,
        uint8 decisionType,
        address deciderAddress,
        address[] memory facetAddresses,
        bytes4[][] memory facetSelectors,
        address initAddress,
        bytes memory _callData
      ) = abi.decode(callData, (string,uint8,address,address[],bytes4[][],address,bytes));
      bytes4 addNewManagementSystemWithFacetsAndStateUpdate = bytes4(keccak256(bytes("addNewManagementSystemWithFacetsAndStateUpdate(string,uint8,address,address[],bytes4[][],address,bytes)")));
      validCallData = abi.encodeWithSelector(
        addNewManagementSystemWithFacetsAndStateUpdate,
        msName,
        decisionType,
        deciderAddress,
        facetAddresses,
        facetSelectors,
        initAddress,
        _callData
      );
    } else if (moduleManagerAction == ModuleManagerAction.RemoveModule) {
      (string memory msName) = abi.decode(callData, (string));
      bytes4 removeModule = bytes4(keccak256(bytes("removeModule(string)")));
      validCallData = abi.encodeWithSelector(removeModule, msName);
    } else if (moduleManagerAction == ModuleManagerAction.ChangeAddressesProvider) {
      (address newAddressesProvider) = abi.decode(callData, (address));
      bytes4 changeAddressesProvider = bytes4(keccak256(bytes("changeAddressesProvider(address)")));
      validCallData = abi.encodeWithSelector(changeAddressesProvider, newAddressesProvider);
    } else if (moduleManagerAction == ModuleManagerAction.DiamondCut) {
      (
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
      ) = abi.decode(callData, (IDiamondCut.FacetCut[],address,bytes));
      bytes4 diamondCut = bytes4(keccak256(bytes("diamondCut((address,uint8,bytes4[])[],address,bytes)")));
      validCallData = abi.encodeWithSelector(
        diamondCut,
        _diamondCut,
        _init,
        _calldata
      );
    } else {
      revert("No valid ModuleManager action was requested.");
    }
    proposalId = LibDecisionProcess.createProposal("setAddChangeManagementSystem", moduleManagerMethods, 0, validCallData);
  }

  function decideOnModuleManagerProposal(uint256 proposalId, bool decision) public  {
    LibDecisionProcess.decideOnProposal("setAddChangeManagementSystem", proposalId, decision);
  }

  function acceptOrRejectModuleManagerProposal(uint256 proposalId) public  {
    LibDecisionProcess.acceptOrRejectProposal("setAddChangeManagementSystem", proposalId);
  }

  function executeModuleManagerProposal(uint256 proposalId) public  returns (bool result) {
    bytes4 thisSelector = bytes4(keccak256(bytes("executeModuleManagerProposal(uint256)")));
    result = LibDecisionProcess.executeProposalDelegateCall("setAddChangeManagementSystem", proposalId, thisSelector);
  }

  // few wrappers

  function switchModuleDeciderInitProposal(
    string memory msName,
    address newDecider
  ) public  returns(uint256 proposalId) {
    bytes memory callData = abi.encode(msName, newDecider);
    proposalId = createModuleManagerProposal(ModuleManagerAction.SwitchModuleDecider, callData);
  }

  function addNewManagementSystemWithFacetsInitProposal(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    address deciderAddress,
    address[] memory facetAddresses,
    bytes4[][] memory facetSelectors
  ) public  returns(uint256 proposalId) {
    bytes memory callData = abi.encode(
      msName,
      decisionType,
      deciderAddress,
      facetAddresses,
      facetSelectors
    );
    proposalId = createModuleManagerProposal(ModuleManagerAction.AddNewModule, callData);
  }

  function addNewManagementSystemWithFacetsAndStateUpdateInitProposal(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    address deciderAddress,
    address[] memory facetAddresses,
    bytes4[][] memory facetSelectors,
    address initAddress,
    bytes memory _callData
  ) public  returns(uint256 proposalId) {
    bytes memory callData = abi.encode(
      msName,
      decisionType,
      deciderAddress,
      facetAddresses,
      facetSelectors,
      initAddress,
      _callData
    );
    proposalId = createModuleManagerProposal(ModuleManagerAction.AddNewModuleAndStateUpdate, callData);
  }

  function removeModuleInitProposal(string memory msName) public returns(uint256 proposalId) {
    bytes memory callData = abi.encode(msName);
    proposalId = createModuleManagerProposal(ModuleManagerAction.RemoveModule, callData);
  }

  function changeAddressesProviderInitProposal(address newAddressesProvider) public returns(uint256 proposalId) {
    bytes memory callData = abi.encode(newAddressesProvider);
    proposalId = createModuleManagerProposal(ModuleManagerAction.ChangeAddressesProvider, callData);
  }

  function diamondCutInitProposal(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) public returns(uint256 proposalId) {
    bytes memory callData = abi.encode(
      _diamondCut,
      _init,
      _calldata
    );
    proposalId = createModuleManagerProposal(ModuleManagerAction.DiamondCut, callData);
  }

  // batch for direct caller
  function batchedModuleManagerProposalExecution(
    ModuleManagerAction moduleManagerAction,
    bytes memory callData
  ) public returns(bool result) {
    uint256 proposalId = createModuleManagerProposal(moduleManagerAction, callData);
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }

  function switchModuleDeciderBatchedExecution(
    string memory msName,
    address newDecider
  ) public returns(bool result) {
    uint256 proposalId = switchModuleDeciderInitProposal(msName, newDecider);
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }

  function addNewManagementSystemWithFacetsBatchedExecution(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    address deciderAddress,
    address[] memory facetAddresses,
    bytes4[][] memory facetSelectors
  ) public returns(bool result) {
    uint256 proposalId = addNewManagementSystemWithFacetsInitProposal(
      msName,
      decisionType,
      deciderAddress,
      facetAddresses,
      facetSelectors
    );
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }

  function addNewManagementSystemWithFacetsAndStateUpdateBatchedExecution(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    address deciderAddress,
    address[] memory facetAddresses,
    bytes4[][] memory facetSelectors,
    address initAddress,
    bytes memory _callData
  ) public  returns(bool result) {
    uint256 proposalId = addNewManagementSystemWithFacetsAndStateUpdateInitProposal(
      msName,
      decisionType,
      deciderAddress,
      facetAddresses,
      facetSelectors,
      initAddress,
      _callData
    );
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }

  function removeModuleBatchedExecution(string memory msName) public returns(bool result) {
    uint256 proposalId = removeModuleInitProposal(msName);
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }

  function changeAddressesProviderBatchedExecution(address newAddressesProvider) public returns(bool result) {
    uint256 proposalId = changeAddressesProviderInitProposal(newAddressesProvider);
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }

  function diamondCutBatchedExecution(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) public  returns(bool result) {
    uint256 proposalId = diamondCutInitProposal(_diamondCut, _init, _calldata);
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }
/*
  // MULTI PROPOSALS
  function createSeveralModuleManagerProposals(
    ModuleManagerAction[] calldata moduleManagerActions,
    bytes[] calldata callDatas
  ) external  returns (uint256[] memory) {
    uint256 numberOfProposals = moduleManagerActions.length;
    require(
      callDatas.length == numberOfProposals,
      "Different array length"
    );
    uint256[] memory proposalIds = new uint256[](numberOfProposals);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      proposalIds[i] = createModuleManagerProposal(
        moduleManagerActions[i],
        callDatas[i]
      );
    }
    return proposalIds;
  }

  function decideOnSeveralModuleManagerProposals(uint256[] calldata proposalsIds, bool[] calldata decisions)
    external

  {
    require(proposalsIds.length == decisions.length, "Different array length");
    for (uint256 i = 0; i < proposalsIds.length; i++) {
      decideOnModuleManagerProposal(proposalsIds[i], decisions[i]);
    }
  }

  function acceptOrRejectSeveralModuleManagerProposals(uint256[] calldata proposalIds) external  {
    for (uint256 i = 0; i < proposalIds.length; i++) {
      acceptOrRejectModuleManagerProposal(proposalIds[i]);
    }
  }

  function executeSeveralModuleManagerProposals(uint256[] memory proposalIds) external  returns (bool[] memory results) {
    results = new bool[](proposalIds.length);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      results[i] = executeModuleManagerProposal(
        proposalIds[i]
      );
    }
  }

  */
}
