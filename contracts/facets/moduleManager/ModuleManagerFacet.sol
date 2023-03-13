// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {IDiamondCut} from "../../interfaces/IDiamondCut.sol";
import {LibDecisionProcess} from "../../libraries/decisionSystem/LibDecisionProcess.sol";

/**
 * @title ModuleManagerFacet - Facet provides functions that handles interactions
 *                         with the DAO module manager.
 * @notice Module manager controls DAO core - modules. Allows to add/remove DAO modules,
 *         switch their decision types and set new deciders, also change AddressesProvider and
 *         make general DAO diamond cut.
 * @author @roleengineer
 */
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

  /**
   * @notice Returns contract address, which includes implementation of module manager actions.
   */
  function getModuleManagerMethods() external view returns (address) {
    return moduleManagerMethods;
  }

  /**
   * @notice Method creates module manager proposal.
   * @param moduleManagerAction One of the module manager actions from a strict set.
   * @param callData Data payload (without selector) for a function from `moduleManagerMethods` related to a chosen action.
   * @return proposalId Newly created module manager proposal id.
   */
  function createModuleManagerProposal(
    ModuleManagerAction moduleManagerAction,
    bytes memory callData
  ) public returns (uint256 proposalId) {
    bytes memory validCallData;
    if (moduleManagerAction == ModuleManagerAction.SwitchModuleDecider) {
      (string memory msName, address newDecider) = abi.decode(callData, (string, address));
      bytes4 switchModuleDecider = bytes4(keccak256(bytes("switchModuleDecider(string,address)")));
      validCallData = abi.encodeWithSelector(switchModuleDecider, msName, newDecider);
    } else if (moduleManagerAction == ModuleManagerAction.AddNewModule) {
      (
        string memory msName,
        uint8 decisionType,
        address deciderAddress,
        address[] memory facetAddresses,
        bytes4[][] memory facetSelectors
      ) = abi.decode(callData, (string, uint8, address, address[], bytes4[][]));
      bytes4 addNewModuleWithFacets = bytes4(
        keccak256(bytes("addNewModuleWithFacets(string,uint8,address,address[],bytes4[][])"))
      );
      validCallData = abi.encodeWithSelector(
        addNewModuleWithFacets,
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
      ) = abi.decode(callData, (string, uint8, address, address[], bytes4[][], address, bytes));
      bytes4 addNewModuleWithFacetsAndStateUpdate = bytes4(
        keccak256(
          bytes(
            "addNewModuleWithFacetsAndStateUpdate(string,uint8,address,address[],bytes4[][],address,bytes)"
          )
        )
      );
      validCallData = abi.encodeWithSelector(
        addNewModuleWithFacetsAndStateUpdate,
        msName,
        decisionType,
        deciderAddress,
        facetAddresses,
        facetSelectors,
        initAddress,
        _callData
      );
    } else if (moduleManagerAction == ModuleManagerAction.RemoveModule) {
      string memory msName = abi.decode(callData, (string));
      bytes4 removeModule = bytes4(keccak256(bytes("removeModule(string)")));
      validCallData = abi.encodeWithSelector(removeModule, msName);
    } else if (moduleManagerAction == ModuleManagerAction.ChangeAddressesProvider) {
      address newAddressesProvider = abi.decode(callData, (address));
      bytes4 changeAddressesProvider = bytes4(keccak256(bytes("changeAddressesProvider(address)")));
      validCallData = abi.encodeWithSelector(changeAddressesProvider, newAddressesProvider);
    } else if (moduleManagerAction == ModuleManagerAction.DiamondCut) {
      (IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) = abi
        .decode(callData, (IDiamondCut.FacetCut[], address, bytes));
      bytes4 diamondCut = bytes4(
        keccak256(bytes("diamondCut((address,uint8,bytes4[])[],address,bytes)"))
      );
      validCallData = abi.encodeWithSelector(diamondCut, _diamondCut, _init, _calldata);
    } else {
      revert("No valid ModuleManager action was requested.");
    }
    proposalId = LibDecisionProcess.createProposal(
      "moduleManager",
      moduleManagerMethods,
      0,
      validCallData
    );
  }

  /**
   * @notice Allows to decide on module manager proposal.
   * @param proposalId The id of module manager proposal to decide on.
   * @param decision True - for proposal, false - against proposal.
   */
  function decideOnModuleManagerProposal(uint256 proposalId, bool decision) public {
    LibDecisionProcess.decideOnProposal("moduleManager", proposalId, decision);
  }

  /**
   * @notice Allows to accept/reject module manager proposal. Should be called when
   *         decision considered to be done based on rules of module manager current decision type.
   * @param proposalId The id of module manager proposal to accept/reject.
   */
  function acceptOrRejectModuleManagerProposal(uint256 proposalId) public {
    LibDecisionProcess.acceptOrRejectProposal("moduleManager", proposalId);
  }

  /**
   * @notice Allows to execute module manager accepted proposal. Should be called at
   *         proposal execution timestamp.
   * @param proposalId The id of module manager proposal to execute.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function executeModuleManagerProposal(uint256 proposalId) public returns (bool result) {
    bytes4 thisSelector = bytes4(keccak256(bytes("executeModuleManagerProposal(uint256)")));
    result = LibDecisionProcess.executeProposalDelegateCall(
      "moduleManager",
      proposalId,
      thisSelector
    );
  }

  /*//////////////////////////////////////////////////////////////
                    WRAPPER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Allows to init module manager proposal to switch module decider.
   * @param msName Module name, which decider should be switched.
   * @param newDecider The new `msName` module decider address.
   * @return proposalId Newly created module manager proposal id.
   */
  function switchModuleDeciderInitProposal(
    string memory msName,
    address newDecider
  ) public returns (uint256 proposalId) {
    bytes memory callData = abi.encode(msName, newDecider);
    proposalId = createModuleManagerProposal(ModuleManagerAction.SwitchModuleDecider, callData);
  }

  /**
   * @notice Allows to init module manager proposal to add new module.
   * @param msName New module name.
   * @param decisionType New `msName` module decision type.
   * @param deciderAddress New `msName` module decider address.
   * @param facetAddresses An array of facet addresses, which provides new module functionality.
   * @param facetSelectors An array of selector array of facet addresses.
   * @return proposalId Newly created module manager proposal id.
   */
  function addNewModuleWithFacetsInitProposal(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    address deciderAddress,
    address[] memory facetAddresses,
    bytes4[][] memory facetSelectors
  ) public returns (uint256 proposalId) {
    bytes memory callData = abi.encode(
      msName,
      decisionType,
      deciderAddress,
      facetAddresses,
      facetSelectors
    );
    proposalId = createModuleManagerProposal(ModuleManagerAction.AddNewModule, callData);
  }

  /**
   * @notice Allows to init module manager proposal to add new module, which requires state initialization.
   * @param msName New module name.
   * @param decisionType New `msName` module decision type.
   * @param deciderAddress New `msName` module decider address.
   * @param facetAddresses An array of facet addresses, which provides new module functionality.
   * @param facetSelectors An array of selector array of facet addresses.
   * @param initAddress Init contract address, which has function to initialize new module state.
   * @param _callData Data payload (with selector) for a init contract function to initialize new module state.
   * @return proposalId Newly created module manager proposal id.
   */
  function addNewModuleWithFacetsAndStateUpdateInitProposal(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    address deciderAddress,
    address[] memory facetAddresses,
    bytes4[][] memory facetSelectors,
    address initAddress,
    bytes memory _callData
  ) public returns (uint256 proposalId) {
    bytes memory callData = abi.encode(
      msName,
      decisionType,
      deciderAddress,
      facetAddresses,
      facetSelectors,
      initAddress,
      _callData
    );
    proposalId = createModuleManagerProposal(
      ModuleManagerAction.AddNewModuleAndStateUpdate,
      callData
    );
  }

  /**
   * @notice Allows to init module manager proposal to remove module.
   * @param msName The name of module, which should be removed.
   * @return proposalId Newly created module manager proposal id.
   */
  function removeModuleInitProposal(string memory msName) public returns (uint256 proposalId) {
    bytes memory callData = abi.encode(msName);
    proposalId = createModuleManagerProposal(ModuleManagerAction.RemoveModule, callData);
  }

  /**
   * @notice Allows to init module manager proposal to change addresses provider.
   * @dev AddressesProvider is a DAO trusted source of facets and init contracts.
   * @param newAddressesProvider Address of the addresses provider contract.
   * @return proposalId Newly created module manager proposal id.
   */
  function changeAddressesProviderInitProposal(
    address newAddressesProvider
  ) public returns (uint256 proposalId) {
    bytes memory callData = abi.encode(newAddressesProvider);
    proposalId = createModuleManagerProposal(ModuleManagerAction.ChangeAddressesProvider, callData);
  }

  /**
   * @notice Allows to init module manager proposal to make a diamond cut.
   *         Diamond cut is a general EIP2535 function to make diamond upgrades.
   * @param _diamondCut An array of FacetCut structs. FacetCut struct contains:
   *                    facetAddress, uint8 action and an array of facet selectors.
   * @param _init Address of the init contract, which is responsible to initialize the state.
   * @param _calldata Data payload (with selector) for init contract function.
   * @return proposalId Newly created module manager proposal id.
   */
  function diamondCutInitProposal(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) public returns (uint256 proposalId) {
    bytes memory callData = abi.encode(_diamondCut, _init, _calldata);
    proposalId = createModuleManagerProposal(ModuleManagerAction.DiamondCut, callData);
  }

  /*//////////////////////////////////////////////////////////////
                BATCHED FUNCTIONS FOR DIRECT CALLER
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Allows direct caller to create/accept/execute governance proposal in one call.
   * @param moduleManagerAction One of module manager actions from a strict set.
   * @param callData Data payload (without selector) for a function from `moduleManagerMethods` related to a chosen action.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function batchedModuleManagerProposalExecution(
    ModuleManagerAction moduleManagerAction,
    bytes memory callData
  ) public returns (bool result) {
    uint256 proposalId = createModuleManagerProposal(moduleManagerAction, callData);
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }

  /**
   * @notice Allows direct caller to create/accept/execute governance proposal
   *         to switch `msName` module decider in one call.
   * @param msName Module name, which decider should be switched.
   * @param newDecider The new `msName` module decider address.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function switchModuleDeciderBatchedExecution(
    string memory msName,
    address newDecider
  ) public returns (bool result) {
    uint256 proposalId = switchModuleDeciderInitProposal(msName, newDecider);
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }

  /**
   * @notice Allows direct caller to create/accept/execute governance proposal
   *         to add new `msName` module in one call.
   * @param msName New module name.
   * @param decisionType New `msName` module decision type.
   * @param deciderAddress New `msName` module decider address.
   * @param facetAddresses An array of facet addresses, which provides new module functionality.
   * @param facetSelectors An array of selector array of facet addresses.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function addNewModuleWithFacetsBatchedExecution(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    address deciderAddress,
    address[] memory facetAddresses,
    bytes4[][] memory facetSelectors
  ) public returns (bool result) {
    uint256 proposalId = addNewModuleWithFacetsInitProposal(
      msName,
      decisionType,
      deciderAddress,
      facetAddresses,
      facetSelectors
    );
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }

  /**
   * @notice Allows direct caller to create/accept/execute governance proposal
   *         to add new `msName` module and initialize state related to it in one call.
   * @param msName New module name.
   * @param decisionType New `msName` module decision type.
   * @param deciderAddress New `msName` module decider address.
   * @param facetAddresses An array of facet addresses, which provides new module functionality.
   * @param facetSelectors An array of selector array of facet addresses.
   * @param initAddress Init contract address, which has function to initialize new module state.
   * @param _callData Data payload (with selector) for a init contract function to initialize new module state.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function addNewModuleWithFacetsAndStateUpdateBatchedExecution(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    address deciderAddress,
    address[] memory facetAddresses,
    bytes4[][] memory facetSelectors,
    address initAddress,
    bytes memory _callData
  ) public returns (bool result) {
    uint256 proposalId = addNewModuleWithFacetsAndStateUpdateInitProposal(
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

  /**
   * @notice Allows direct caller to create/accept/execute governance proposal
   *         to remove `msName` module in one call.
   * @param msName The name of module, which should be removed.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function removeModuleBatchedExecution(string memory msName) public returns (bool result) {
    uint256 proposalId = removeModuleInitProposal(msName);
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }

  /**
   * @notice Allows direct caller to create/accept/execute governance proposal
   *         to change addresses provider in one call.
   * @dev AddressesProvider is a DAO trusted source of facets and init contracts.
   * @param newAddressesProvider Address of the addresses provider contract.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function changeAddressesProviderBatchedExecution(
    address newAddressesProvider
  ) public returns (bool result) {
    uint256 proposalId = changeAddressesProviderInitProposal(newAddressesProvider);
    acceptOrRejectModuleManagerProposal(proposalId);
    result = executeModuleManagerProposal(proposalId);
  }

  /**
   * @notice Allows direct caller to create/accept/execute governance proposal
   *         to make EIP2535 diamond cut in one call.
   * @param _diamondCut An array of FacetCut structs. FacetCut struct contains:
   *                    facetAddress, uint8 action and an array of facet selectors.
   * @param _init Address of the init contract, which is responsible to initialize the state.
   * @param _calldata Data payload (with selector) for init contract function.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function diamondCutBatchedExecution(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) public returns (bool result) {
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
