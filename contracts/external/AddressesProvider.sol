// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";

contract AddressesProvider is IAddressesProvider { // Registry - rename
  address owner; // replace later with openzeppelin

  // Init identifiers
  bytes32 private constant VOTING_POWER_INIT = 'VOTING_POWER_INIT';
  bytes32 private constant TREASUTY_INIT = 'TREASUTY_INIT';
  bytes32 private constant GOVERNANCE_INIT = 'GOVERNANCE_INIT';
  bytes32 private constant DAO_INIT = 'DAO_INIT';
  bytes32 private constant SUBDAO_INIT = 'SUBDAO_INIT';
  // governance tokens
  bytes32 private constant WETH = 'WETH';
  bytes32 private constant UNISWAP_V2_FACTORY = 'UNISWAP_V2_FACTORY';
  bytes32 private constant SUSHI_V2_FACTORY = 'SUSHI_V2_FACTORY';
  bytes32 private constant HABITAT_DIAMOND_FACTORY = 'HABITAT_DIAMOND_FACTORY';
  // later add facets
  bytes32 private constant DIAMOND_CUT_FACET = 'DIAMOND_CUT_FACET';
  bytes32 private constant VOTING_POWER_FACET = 'VOTING_POWER_FACET';
  bytes32 private constant DAO_VIEWER_FACET = 'DAO_VIEWER_FACET';


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
  function getVotingPowerInit() external view override returns(address) {
    return getAddress(VOTING_POWER_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getTreasuryInit() external view override returns(address) {
    return getAddress(TREASUTY_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getGovernanceInit() external view override returns(address) {
    return getAddress(GOVERNANCE_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getDAOInit() external view override returns(address) {
    return getAddress(DAO_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getSubDAOInit() external view override returns(address) {
    return getAddress(SUBDAO_INIT);
  }

  /// @inheritdoc IAddressesProvider
  function getWETH() external view override returns(address) {
    return getAddress(WETH);
  }

  /// @inheritdoc IAddressesProvider
  function getUniswapV2Factory() external view override returns(address) {
    return getAddress(UNISWAP_V2_FACTORY);
  }

  /// @inheritdoc IAddressesProvider
  function getSushiV2Factory() external view override returns(address) {
    return getAddress(SUSHI_V2_FACTORY);
  }

  /// @inheritdoc IAddressesProvider
  function getHabitatDiamondFactory() external view override returns(address) {
    return getAddress(HABITAT_DIAMOND_FACTORY);
  }

  /// @inheritdoc IAddressesProvider
  function getDiamondCutFacetAddress() external view override returns(address) {
    return getAddress(DIAMOND_CUT_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getDAOViewerFacetAddress() external view override returns(address) {
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
  function getDiamondCutFacet() external view override returns(Facet memory) {
    address diamondCutFacet = getAddress(DIAMOND_CUT_FACET);
    return Facet({
      facetAddress: diamondCutFacet,
      functionSelectors: getSelectors(diamondCutFacet)
    });
  }

  /// @inheritdoc IAddressesProvider
  function getVotingPowerFacetAddress() external view override returns(address) {
    return getAddress(VOTING_POWER_FACET);
  }

  /// @inheritdoc IAddressesProvider
  function getVotingPowerFacet() external view override returns(Facet memory) {
    address votingPowerFacet = getAddress(VOTING_POWER_FACET);
    return Facet({
      facetAddress: votingPowerFacet,
      functionSelectors: getSelectors(votingPowerFacet)
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
  function setVotingPowerInit(address newVotingPowerInit) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldVotingPowerInit = _addresses[VOTING_POWER_INIT];
    _addresses[VOTING_POWER_INIT] = newVotingPowerInit;
    emit VotingPowerInitUpdated(oldVotingPowerInit, newVotingPowerInit);
  }

  /// @inheritdoc IAddressesProvider
  function setTreasuryInit(address newTreasuryInit) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldTreasuryInit = _addresses[TREASUTY_INIT];
    _addresses[TREASUTY_INIT] = newTreasuryInit;
    emit TreasuryInitUpdated(oldTreasuryInit, newTreasuryInit);
  }

  /// @inheritdoc IAddressesProvider
  function setGovernanceInit(address newGovernanceInit) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldGovernanceInit = _addresses[GOVERNANCE_INIT];
    _addresses[GOVERNANCE_INIT] = newGovernanceInit;
    emit GovernanceInitUpdated(oldGovernanceInit, newGovernanceInit);
  }

  /// @inheritdoc IAddressesProvider
  function setDAOInit(address newDAOInit) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldDAOInit = _addresses[DAO_INIT];
    _addresses[DAO_INIT] = newDAOInit;
    emit DAOInitUpdated(oldDAOInit, newDAOInit);
  }

  /// @inheritdoc IAddressesProvider
  function setSubDAOInit(address newSubDAOInit) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldSubDAOInit = _addresses[SUBDAO_INIT];
    _addresses[SUBDAO_INIT] = newSubDAOInit;
    emit SubDAOInitUpdated(oldSubDAOInit, newSubDAOInit);
  }

  /// @inheritdoc IAddressesProvider
  function setWETH(address newWETH) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldWETH = _addresses[WETH];
    _addresses[WETH] = newWETH;
    emit WETHUpdated(oldWETH, newWETH);
  }

  /// @inheritdoc IAddressesProvider
  function setUniswapV2Factory(address newUniswapV2Factory) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldUniswapV2Factory = _addresses[UNISWAP_V2_FACTORY];
    _addresses[UNISWAP_V2_FACTORY] = newUniswapV2Factory;
    emit UniswapV2FactoryUpdated(oldUniswapV2Factory, newUniswapV2Factory);
  }

  /// @inheritdoc IAddressesProvider
  function setSushiV2Factory(address newSushiV2Factory) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldSushiV2Factory = _addresses[SUSHI_V2_FACTORY];
    _addresses[SUSHI_V2_FACTORY] = newSushiV2Factory;
    emit SushiV2FactoryUpdated(oldSushiV2Factory, newSushiV2Factory);
  }

  /// @inheritdoc IAddressesProvider
  function setHabitatDiamondFactory(address newHabitatDiamondFactory) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldHabitatDiamondFactory = _addresses[HABITAT_DIAMOND_FACTORY];
    _addresses[HABITAT_DIAMOND_FACTORY] = newHabitatDiamondFactory;
    emit HabitatDiamondFactoryUpdated(oldHabitatDiamondFactory, newHabitatDiamondFactory);
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
  function setVotingPowerFacet(address newVotingPowerFacet, bytes4[] memory selectors) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldVotingPowerFacet = _addresses[VOTING_POWER_FACET];
    _addresses[VOTING_POWER_FACET] = newVotingPowerFacet;
    _selectors[newVotingPowerFacet] = selectors;
    emit DiamondCutFacetUpdated(oldVotingPowerFacet, newVotingPowerFacet);
  }

  /// @inheritdoc IAddressesProvider
  function setDAOViewerFacet(address newDAOViewerFacet, bytes4[] memory selectors) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldDAOViewerFacet = _addresses[DAO_VIEWER_FACET];
    _addresses[DAO_VIEWER_FACET] = newDAOViewerFacet;
    _selectors[newVotingPowerFacet] = selectors;
    emit DAOViewerFacetUpdated(oldDAOViewerFacet, newDAOViewerFacet);
  }

  function setNewOwner(address newOwner) external {
    require(msg.sender == owner, "Only owner can call.");
    owner = newOwner;
  }

}
