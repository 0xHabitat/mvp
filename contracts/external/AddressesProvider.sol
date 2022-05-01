// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";

contract AddressesProvider is IAddressesProvider {
  address owner; // replace later with openzeppelin

  // Main identifiers
  bytes32 private constant VOTING_POWER_INIT = 'VOTING_POWER_INIT';
  bytes32 private constant TREASUTY_INIT = 'TREASUTY_INIT';
  bytes32 private constant GOVERNANCE_INIT = 'GOVERNANCE_INIT';
  bytes32 private constant SUBDAO_INIT = 'SUBDAO_INIT';
  // later add facets

  // Map of registered addresses (identifier => registeredAddress)
  mapping(bytes32 => address) private _addresses;

  constructor() {
    owner = msg.sender;
  }

  /// @inheritdoc IAddressesProvider
  function getAddress(bytes32 id) public view override returns (address) {
    return _addresses[id];
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
  function getSubDAOInit() external view override returns(address) {
    return getAddress(SUBDAO_INIT);
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
  function setSubDAOInit(address newSubDAOInit) external override {
    require(msg.sender == owner, "Only owner can call.");
    address oldSubDAOInit = _addresses[SUBDAO_INIT];
    _addresses[SUBDAO_INIT] = newSubDAOInit;
    emit SubDAOInitUpdated(oldSubDAOInit, newSubDAOInit);
  }

  function setNewOwner(address newOwner) external {
    require(msg.sender == owner, "Only owner can call.");
    owner = newOwner;
  }

}
