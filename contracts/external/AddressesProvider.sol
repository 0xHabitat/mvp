// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";

contract AddressesProvider is
  IAddressesProvider // Registry - rename
{
  address owner; // replace later with openzeppelin

  // Init identifiers
  bytes32 private constant DIAMOND_INIT = "DIAMOND_INIT";
  bytes32 private constant DAO_INIT = "DAO_INIT";
  bytes32 private constant MANAGEMENT_SYSTEMS_INIT = "MANAGEMENT_SYSTEMS_INIT";
  bytes32 private constant SPECIFIC_DATA_INIT = "SPECIFIC_DATA_INIT";
  bytes32 private constant TEMPORARY_INIT = "TEMPORARY_INIT";

  // later add facets
  bytes32 private constant DIAMOND_CUT_FACET = "DIAMOND_CUT_FACET";
  bytes32 private constant OWNERSHIP_FACET = "OWNERSHIP_FACET";
  bytes32 private constant DIAMOND_LOUPE_FACET = "DIAMOND_LOUPE_FACET";
  bytes32 private constant DAO_VIEWER_FACET = "DAO_VIEWER_FACET";
  bytes32 private constant MODULE_VIEWER_FACET = "MODULE_VIEWER_FACET";
  bytes32 private constant MANAGEMENT_SYSTEM_FACET = "MANAGEMENT_SYSTEM_FACET";
  bytes32 private constant MODULE_MANAGER_FACET = "MODULE_MANAGER_FACET";
  bytes32 private constant GOVERNANCE_FACET = "GOVERNANCE_FACET";
  bytes32 private constant TREASURY_ACTIONS_FACET = "TREASURY_ACTIONS_FACET";
  bytes32 private constant TREASURY_DEFAULT_CALLBACK_FACET = "TREASURY_DEFAULT_CALLBACK_FACET";
  bytes32 private constant SPECIFIC_DATA_FACET = "SPECIFIC_DATA_FACET";

  // Map of registered addresses (identifier => registeredAddress)
  mapping(bytes32 => address) private _addresses;
  // Map of registered facet selectors (facetAddress => facetSelectors[])
  //TODO think if i need do delete old address selectors?
  mapping(address => bytes4[]) private _selectors;
  // Map of related facet and init (facetAddress => initAddress)
  mapping(address => address) private _facetToInit;

  constructor() {
    owner = msg.sender;
  }

  /// @inheritdoc IAddressesProvider
  function getAddress(bytes32 id) public view override returns (address) {
    return _addresses[id];
  }

  /// @inheritdoc IAddressesProvider
  function getSelectors(address facet) public view override returns (bytes4[] memory) {
    return _selectors[facet];
  }

  /// @inheritdoc IAddressesProvider
  function facetAddressExist(address facet) public view override returns (bool) {
    bytes4[] memory selectors = getSelectors(facet);
    return selectors.length > 0;
  }

  /// @inheritdoc IAddressesProvider
  function getInitForFacet(address facet) public view override returns (address) {
    return _facetToInit[facet];
  }

  /// @inheritdoc IAddressesProvider
  function getRemoveDiamondCutInit() external view override returns (address) {
    return getAddress(TEMPORARY_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getDiamondInit() external view override returns (address) {
    return getAddress(DIAMOND_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getDAOInit() external view override returns (address) {
    return getAddress(DAO_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getManagementSystemsInit() external view override returns (address) {
    return getAddress(MANAGEMENT_SYSTEMS_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getSpecificDataInit() external view override returns (address) {
    return getAddress(SPECIFIC_DATA_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getDiamondCutFacetAddress() external view override returns (address) {
    return getAddress(DIAMOND_CUT_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getDiamondCutFacet() external view override returns (Facet memory) {
    address diamondCutFacet = getAddress(DIAMOND_CUT_FACET);
    return Facet({facetAddress: diamondCutFacet, functionSelectors: getSelectors(diamondCutFacet)});
  }

  /// @inheritdoc IAddressesProvider
  function getOwnershipFacetAddress() external view override returns (address) {
    return getAddress(OWNERSHIP_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getOwnershipFacet() external view override returns (Facet memory) {
    address ownershipFacet = getAddress(OWNERSHIP_FACET);
    return Facet({facetAddress: ownershipFacet, functionSelectors: getSelectors(ownershipFacet)});
  }

  /// @inheritdoc IAddressesProvider
  function getDiamondLoupeFacetAddress() external view override returns (address) {
    return getAddress(DIAMOND_LOUPE_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getDiamondLoupeFacet() external view override returns (Facet memory) {
    address diamondLoupeFacet = getAddress(DIAMOND_LOUPE_FACET);
    return
      Facet({facetAddress: diamondLoupeFacet, functionSelectors: getSelectors(diamondLoupeFacet)});
  }

  /// @inheritdoc IAddressesProvider
  function getDAOViewerFacetAddress() external view returns (address) {
    return getAddress(DAO_VIEWER_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getDAOViewerFacet() external view override returns (Facet memory) {
    address daoViewerFacet = getAddress(DAO_VIEWER_FACET);
    return Facet({facetAddress: daoViewerFacet, functionSelectors: getSelectors(daoViewerFacet)});
  }

  /// @inheritdoc IAddressesProvider
  function getModuleViewerFacetAddress() external view returns (address) {
    return getAddress(MODULE_VIEWER_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getModuleViewerFacet() external view override returns (Facet memory) {
    address moduleViewerFacet = getAddress(MODULE_VIEWER_FACET);
    return
      Facet({facetAddress: moduleViewerFacet, functionSelectors: getSelectors(moduleViewerFacet)});
  }

  /// @inheritdoc IAddressesProvider
  function getManagementSystemFacetAddress() external view returns (address) {
    return getAddress(MANAGEMENT_SYSTEM_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getManagementSystemFacet() external view override returns (Facet memory) {
    address managementSystemFacet = getAddress(MANAGEMENT_SYSTEM_FACET);
    return
      Facet({
        facetAddress: managementSystemFacet,
        functionSelectors: getSelectors(managementSystemFacet)
      });
  }

  /// @inheritdoc IAddressesProvider
  function getModuleManagerFacetAddress() external view returns (address) {
    return getAddress(MODULE_MANAGER_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getModuleManagerFacet() external view override returns (Facet memory) {
    address moduleManagerFacet = getAddress(MODULE_MANAGER_FACET);
    return
      Facet({
        facetAddress: moduleManagerFacet,
        functionSelectors: getSelectors(moduleManagerFacet)
      });
  }

  /// @inheritdoc IAddressesProvider
  function getGovernanceFacetAddress() external view returns (address) {
    return getAddress(GOVERNANCE_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getGovernanceFacet() external view override returns (Facet memory) {
    address governanceFacet = getAddress(GOVERNANCE_FACET);
    return Facet({facetAddress: governanceFacet, functionSelectors: getSelectors(governanceFacet)});
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryActionsFacetAddress() external view returns (address) {
    return getAddress(TREASURY_ACTIONS_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryActionsFacet() external view override returns (Facet memory) {
    address treasuryActionsFacet = getAddress(TREASURY_ACTIONS_FACET);
    return
      Facet({
        facetAddress: treasuryActionsFacet,
        functionSelectors: getSelectors(treasuryActionsFacet)
      });
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryDefaultCallbackHandlerFacetAddress() external view returns (address) {
    return getAddress(TREASURY_DEFAULT_CALLBACK_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryDefaultCallbackHandlerFacet() external view override returns (Facet memory) {
    address treasuryDefaultCallbackHandlerFacet = getAddress(TREASURY_DEFAULT_CALLBACK_FACET);
    return
      Facet({
        facetAddress: treasuryDefaultCallbackHandlerFacet,
        functionSelectors: getSelectors(treasuryDefaultCallbackHandlerFacet)
      });
  }

  /// @inheritdoc IAddressesProvider
  function getSpecificDataFacetAddress() external view returns (address) {
    return getAddress(SPECIFIC_DATA_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getSpecificDataFacet() external view override returns (Facet memory) {
    address specificDataFacet = getAddress(SPECIFIC_DATA_FACET);
    return
      Facet({facetAddress: specificDataFacet, functionSelectors: getSelectors(specificDataFacet)});
  }

  /// @inheritdoc IAddressesProvider
  function setAddress(bytes32 id, address newAddress) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldAddress = _addresses[id];
    _addresses[id] = newAddress;
    emit AddressSet(id, oldAddress, newAddress);
  }

  /// @inheritdoc IAddressesProvider
  function setRemoveDiamondCutInit(address init) external override {
    require(msg.sender == owner, "Only owner can call.");
    _addresses[TEMPORARY_INIT] = init;
  }

  /// @inheritdoc IAddressesProvider
  function setDiamondInit(address newDiamondInit) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldDiamondInit = _addresses[DIAMOND_INIT];
    _addresses[DIAMOND_INIT] = newDiamondInit;
    emit DiamondInitUpdated(oldDiamondInit, newDiamondInit);
  }

  /// @inheritdoc IAddressesProvider
  function setDAOInit(address newDAOInit) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldDAOInit = _addresses[DAO_INIT];
    _addresses[DAO_INIT] = newDAOInit;
    emit DAOInitUpdated(oldDAOInit, newDAOInit);
  }

  /// @inheritdoc IAddressesProvider
  function setManagementSystemsInit(address newManagementSystemsInit) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldManagementSystemsInit = _addresses[MANAGEMENT_SYSTEMS_INIT];
    _addresses[MANAGEMENT_SYSTEMS_INIT] = newManagementSystemsInit;
    emit ManagementSystemsInitUpdated(oldManagementSystemsInit, newManagementSystemsInit);
  }

  /// @inheritdoc IAddressesProvider
  function setSpecificDataInit(address newSpecificDataInit) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldSpecificDataInit = _addresses[SPECIFIC_DATA_INIT];
    _addresses[SPECIFIC_DATA_INIT] = newSpecificDataInit;
    emit SpecificDataInitUpdated(oldSpecificDataInit, newSpecificDataInit);
  }

  /// @inheritdoc IAddressesProvider
  function setDiamondCutFacet(
    address newDiamondCutFacet,
    bytes4[] memory selectors
  ) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldDiamondCutFacet = _addresses[DIAMOND_CUT_FACET];
    _addresses[DIAMOND_CUT_FACET] = newDiamondCutFacet;
    _selectors[newDiamondCutFacet] = selectors;
    _facetToInit[newDiamondCutFacet] = getAddress(DIAMOND_INIT);
    emit DiamondCutFacetUpdated(oldDiamondCutFacet, newDiamondCutFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setOwnershipFacet(
    address newOwnershipFacet,
    bytes4[] memory selectors
  ) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldOwnershipFacet = _addresses[OWNERSHIP_FACET];
    _addresses[OWNERSHIP_FACET] = newOwnershipFacet;
    _selectors[newOwnershipFacet] = selectors;
    _facetToInit[newOwnershipFacet] = getAddress(DIAMOND_INIT);
    emit OwnershipFacetUpdated(oldOwnershipFacet, newOwnershipFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setDiamondLoupeFacet(
    address newDiamondLoupeFacet,
    bytes4[] memory selectors
  ) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldDiamondLoupeFacet = _addresses[DIAMOND_LOUPE_FACET];
    _addresses[DIAMOND_LOUPE_FACET] = newDiamondLoupeFacet;
    _selectors[newDiamondLoupeFacet] = selectors;
    _facetToInit[newDiamondLoupeFacet] = getAddress(DIAMOND_INIT);
    emit DiamondLoupeFacetUpdated(oldDiamondLoupeFacet, newDiamondLoupeFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setDAOViewerFacet(
    address newDAOViewerFacet,
    bytes4[] memory selectors
  ) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldDAOViewerFacet = _addresses[DAO_VIEWER_FACET];
    _addresses[DAO_VIEWER_FACET] = newDAOViewerFacet;
    _selectors[newDAOViewerFacet] = selectors;
    _facetToInit[newDAOViewerFacet] = getAddress(DAO_INIT);
    emit DAOViewerFacetUpdated(oldDAOViewerFacet, newDAOViewerFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setModuleViewerFacet(
    address newModuleViewerFacet,
    bytes4[] memory selectors
  ) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldModuleViewerFacet = _addresses[MODULE_VIEWER_FACET];
    _addresses[MODULE_VIEWER_FACET] = newModuleViewerFacet;
    _selectors[newModuleViewerFacet] = selectors;
    _facetToInit[newModuleViewerFacet] = getAddress(MANAGEMENT_SYSTEMS_INIT);
    emit ModuleViewerFacetUpdated(oldModuleViewerFacet, newModuleViewerFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setManagementSystemFacet(
    address newManagementSystemFacet,
    bytes4[] memory selectors
  ) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldManagementSystemFacet = _addresses[MANAGEMENT_SYSTEM_FACET];
    _addresses[MANAGEMENT_SYSTEM_FACET] = newManagementSystemFacet;
    _selectors[newManagementSystemFacet] = selectors;
    _facetToInit[newManagementSystemFacet] = getAddress(MANAGEMENT_SYSTEMS_INIT);
    emit ManagementSystemFacetUpdated(oldManagementSystemFacet, newManagementSystemFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setModuleManagerFacet(
    address newModuleManagerFacet,
    bytes4[] memory selectors
  ) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldModuleManagerFacet = _addresses[MODULE_MANAGER_FACET];
    _addresses[MODULE_MANAGER_FACET] = newModuleManagerFacet;
    _selectors[newModuleManagerFacet] = selectors;
    //_facetToInit[newModuleManagerFacet] = getAddress();
    emit ModuleManagerFacetUpdated(oldModuleManagerFacet, newModuleManagerFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setGovernanceFacet(
    address newGovernanceFacet,
    bytes4[] memory selectors
  ) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldGovernanceFacet = _addresses[GOVERNANCE_FACET];
    _addresses[GOVERNANCE_FACET] = newGovernanceFacet;
    _selectors[newGovernanceFacet] = selectors;
    //_facetToInit[newGovernanceFacet] = getAddress();
    emit GovernanceFacetUpdated(oldGovernanceFacet, newGovernanceFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setTreasuryActionsFacet(
    address newTreasuryActionsFacet,
    bytes4[] memory selectors
  ) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldTreasuryActionsFacet = _addresses[TREASURY_ACTIONS_FACET];
    _addresses[TREASURY_ACTIONS_FACET] = newTreasuryActionsFacet;
    _selectors[newTreasuryActionsFacet] = selectors;
    emit TreasuryActionsFacetUpdated(oldTreasuryActionsFacet, newTreasuryActionsFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setTreasuryDefaultCallbackHandlerFacet(
    address newTreasuryDefaultCallbackHandlerFacet,
    bytes4[] memory selectors
  ) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldTreasuryDefaultCallbackHandlerFacet = _addresses[TREASURY_DEFAULT_CALLBACK_FACET];
    _addresses[TREASURY_DEFAULT_CALLBACK_FACET] = newTreasuryDefaultCallbackHandlerFacet;
    _selectors[newTreasuryDefaultCallbackHandlerFacet] = selectors;
    emit TreasuryDefaultCallbackHandlerFacetUpdated(
      oldTreasuryDefaultCallbackHandlerFacet,
      newTreasuryDefaultCallbackHandlerFacet
    );
  }

  /// @inheritdoc IAddressesProvider
  function setSpecificDataFacet(
    address newSpecificDataFacet,
    bytes4[] memory selectors
  ) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldSpecificDataFacet = _addresses[SPECIFIC_DATA_FACET];
    _addresses[SPECIFIC_DATA_FACET] = newSpecificDataFacet;
    _selectors[newSpecificDataFacet] = selectors;
    _facetToInit[newSpecificDataFacet] = getAddress(SPECIFIC_DATA_INIT);
    emit SpecificDataFacetUpdated(oldSpecificDataFacet, newSpecificDataFacet);
  }

  function setNewOwner(address newOwner) external {
    require(msg.sender == owner, "Only owner can call.");
    owner = newOwner;
  }

  function getAddressAndFunctionToCall(bytes32 nameOrType) external view returns (address, bytes4) {
    revert("not implemented");
  }
}
