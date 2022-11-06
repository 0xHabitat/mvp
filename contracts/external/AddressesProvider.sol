// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";

contract AddressesProvider is IAddressesProvider { // Registry - rename
  address owner; // replace later with openzeppelin

  // Init identifiers
  bytes32 private constant DIAMOND_INIT = 'DIAMOND_INIT';
  bytes32 private constant DAO_INIT = 'DAO_INIT';
  bytes32 private constant MANAGEMENT_SYSTEMS_INIT = 'MANAGEMENT_SYSTEMS_INIT';
  bytes32 private constant TREASURY_INIT = 'TREASURY_INIT';

  // later add facets
  bytes32 private constant DIAMOND_CUT_FACET = 'DIAMOND_CUT_FACET';
  bytes32 private constant OWNERSHIP_FACET = 'OWNERSHIP_FACET';
  bytes32 private constant DIAMOND_LOUPE_FACET = 'DIAMOND_LOUPE_FACET';
  bytes32 private constant DAO_VIEWER_FACET = 'DAO_VIEWER_FACET';
  // when MANAGEMENT_SYSTEM_FACET is ready add
  bytes32 private constant TREASURY_ACTIONS_FACET = 'TREASURY_ACTIONS_FACET';
  bytes32 private constant TREASURY_VIEWER_FACET = 'TREASURY_VIEWER_FACET';
  bytes32 private constant TREASURY_DEFAULT_CALLBACK_FACET = 'TREASURY_DEFAULT_CALLBACK_FACET';
  bytes32 private constant VOTING_POWER_SPECIFIC_DATA_FACET = 'VOTING_POWER_SPECIFIC_DATA_FACET';


  // Map of registered addresses (identifier => registeredAddress)
  mapping(bytes32 => address) private _addresses;
  // Map of registered facet selectors (facetAddress => facetSelectors[])
  mapping(address => bytes4[]) private _selectors;

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
  function getDiamondInit() external view override returns(address) {
    return getAddress(DIAMOND_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getDAOInit() external view override returns(address) {
    return getAddress(DAO_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getManagementSystemsInit() external view override returns(address) {
    return getAddress(MANAGEMENT_SYSTEMS_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryInit() external view override returns(address) {
    return getAddress(TREASURY_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getDiamondCutFacetAddress() external view override returns(address) {
    return getAddress(DIAMOND_CUT_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getDiamondCutFacet() external view override returns(Facet memory) {
    address diamondCutFacet = getAddress(DIAMOND_CUT_FACET);
    return Facet({
      facetAddress: diamondCutFacet,
      functionSelectors: getSelectors(diamondCutFacet)
    });
  }

  /// @inheritdoc IAddressesProvider
  function getOwnershipFacetAddress() external view override returns(address) {
    return getAddress(OWNERSHIP_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getOwnershipFacet() external view override returns(Facet memory) {
    address ownershipFacet = getAddress(OWNERSHIP_FACET);
    return Facet({
      facetAddress: ownershipFacet,
      functionSelectors: getSelectors(ownershipFacet)
    });
  }

  /// @inheritdoc IAddressesProvider
  function getDiamondLoupeFacetAddress() external view override returns(address) {
    return getAddress(DIAMOND_LOUPE_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getDiamondLoupeFacet() external view override returns(Facet memory) {
    address diamondLoupeFacet = getAddress(DIAMOND_LOUPE_FACET);
    return Facet({
      facetAddress: diamondLoupeFacet,
      functionSelectors: getSelectors(diamondLoupeFacet)
    });
  }

  /// @inheritdoc IAddressesProvider
  function getDAOViewerFacetAddress() external view returns(address) {
    return getAddress(DAO_VIEWER_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getDAOViewerFacet() external view override returns(Facet memory) {
    address daoViewerFacet = getAddress(DAO_VIEWER_FACET);
    return Facet({
      facetAddress: daoViewerFacet,
      functionSelectors: getSelectors(daoViewerFacet)
    });
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryActionsFacetAddress() external view returns(address) {
    return getAddress(TREASURY_ACTIONS_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryActionsFacet() external view override returns(Facet memory) {
    address treasuryActionsFacet = getAddress(TREASURY_ACTIONS_FACET);
    return Facet({
      facetAddress: treasuryActionsFacet,
      functionSelectors: getSelectors(treasuryActionsFacet)
    });
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryViewerFacetAddress() external view returns(address) {
    return getAddress(TREASURY_VIEWER_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryViewerFacet() external view override returns(Facet memory) {
    address treasuryViewerFacet = getAddress(TREASURY_VIEWER_FACET);
    return Facet({
      facetAddress: treasuryViewerFacet,
      functionSelectors: getSelectors(treasuryViewerFacet)
    });
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryDefaultCallbackHandlerFacetAddress() external view returns(address) {
    return getAddress(TREASURY_DEFAULT_CALLBACK_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryDefaultCallbackHandlerFacet() external view override returns(Facet memory) {
    address treasuryDefaultCallbackHandlerFacet = getAddress(TREASURY_DEFAULT_CALLBACK_FACET);
    return Facet({
      facetAddress: treasuryDefaultCallbackHandlerFacet,
      functionSelectors: getSelectors(treasuryDefaultCallbackHandlerFacet)
    });
  }

  /// @inheritdoc IAddressesProvider
  function getVotingPowerSpecificDataFacetAddress() external view returns(address) {
    return getAddress(VOTING_POWER_SPECIFIC_DATA_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getVotingPowerSpecificDataFacet() external view override returns(Facet memory) {
    address votingPowerSpecificDataFacet = getAddress(VOTING_POWER_SPECIFIC_DATA_FACET);
    return Facet({
      facetAddress: votingPowerSpecificDataFacet,
      functionSelectors: getSelectors(votingPowerSpecificDataFacet)
    });
  }

  /// @inheritdoc IAddressesProvider
  function setAddress(bytes32 id, address newAddress) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldAddress = _addresses[id];
    _addresses[id] = newAddress;
    emit AddressSet(id, oldAddress, newAddress);
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
  function setTreasuryInit(address newTreasuryInit) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldTreasuryInit = _addresses[TREASURY_INIT];
    _addresses[TREASURY_INIT] = newTreasuryInit;
    emit TreasuryInitUpdated(oldTreasuryInit, newTreasuryInit);
  }

  /// @inheritdoc IAddressesProvider
  function setDiamondCutFacet(address newDiamondCutFacet, bytes4[] memory selectors) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldDiamondCutFacet = _addresses[DIAMOND_CUT_FACET];
    _addresses[DIAMOND_CUT_FACET] = newDiamondCutFacet;
    _selectors[newDiamondCutFacet] = selectors;
    emit DiamondCutFacetUpdated(oldDiamondCutFacet, newDiamondCutFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setOwnershipFacet(address newOwnershipFacet, bytes4[] memory selectors) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldOwnershipFacet = _addresses[OWNERSHIP_FACET];
    _addresses[OWNERSHIP_FACET] = newOwnershipFacet;
    _selectors[newOwnershipFacet] = selectors;
    emit OwnershipFacetUpdated(oldOwnershipFacet, newOwnershipFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setDiamondLoupeFacet(address newDiamondLoupeFacet, bytes4[] memory selectors) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldDiamondLoupeFacet = _addresses[DIAMOND_LOUPE_FACET];
    _addresses[DIAMOND_LOUPE_FACET] = newDiamondLoupeFacet;
    _selectors[newDiamondLoupeFacet] = selectors;
    emit DiamondLoupeFacetUpdated(oldDiamondLoupeFacet, newDiamondLoupeFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setDAOViewerFacet(address newDAOViewerFacet, bytes4[] memory selectors) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldDAOViewerFacet = _addresses[DAO_VIEWER_FACET];
    _addresses[DAO_VIEWER_FACET] = newDAOViewerFacet;
    _selectors[newDAOViewerFacet] = selectors;
    emit DAOViewerFacetUpdated(oldDAOViewerFacet, newDAOViewerFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setTreasuryActionsFacet(address newTreasuryActionsFacet, bytes4[] memory selectors) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldTreasuryActionsFacet = _addresses[TREASURY_ACTIONS_FACET];
    _addresses[TREASURY_ACTIONS_FACET] = newTreasuryActionsFacet;
    _selectors[newTreasuryActionsFacet] = selectors;
    emit TreasuryActionsFacetUpdated(oldTreasuryActionsFacet, newTreasuryActionsFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setTreasuryViewerFacet(address newTreasuryViewerFacet, bytes4[] memory selectors) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldTreasuryViewerFacet = _addresses[TREASURY_VIEWER_FACET];
    _addresses[TREASURY_VIEWER_FACET] = newTreasuryViewerFacet;
    _selectors[newTreasuryViewerFacet] = selectors;
    emit TreasuryViewerFacetUpdated(oldTreasuryViewerFacet, newTreasuryViewerFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setTreasuryDefaultCallbackHandlerFacet(address newTreasuryDefaultCallbackHandlerFacet, bytes4[] memory selectors) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldTreasuryDefaultCallbackHandlerFacet = _addresses[TREASURY_DEFAULT_CALLBACK_FACET];
    _addresses[TREASURY_DEFAULT_CALLBACK_FACET] = newTreasuryDefaultCallbackHandlerFacet;
    _selectors[newTreasuryDefaultCallbackHandlerFacet] = selectors;
    emit TreasuryDefaultCallbackHandlerFacetUpdated(oldTreasuryDefaultCallbackHandlerFacet, newTreasuryDefaultCallbackHandlerFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setVotingPowerSpecificDataFacet(address newVotingPowerSpecificDataFacet, bytes4[] memory selectors) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldVotingPowerSpecificDataFacet = _addresses[VOTING_POWER_SPECIFIC_DATA_FACET];
    _addresses[VOTING_POWER_SPECIFIC_DATA_FACET] = newVotingPowerSpecificDataFacet;
    _selectors[newVotingPowerSpecificDataFacet] = selectors;
    emit VotingPowerSpecificDataFacetUpdated(oldVotingPowerSpecificDataFacet, newVotingPowerSpecificDataFacet);
  }

  function setNewOwner(address newOwner) external {
    require(msg.sender == owner, "Only owner can call.");
    owner = newOwner;
  }
  function getAddressAndFunctionToCall(bytes32 nameOrType) external view returns (address,bytes4) {
    revert("not implemented");
  }

}
