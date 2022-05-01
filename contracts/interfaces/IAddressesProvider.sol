// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title IAddressesProvider
 * @author HabitatDAO
 * @notice Defines the basic interface for an Addresses Provider.
 **/
interface IAddressesProvider {

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the voting power init is updated.
   * @param oldAddress The old address of the VotingPowerInit
   * @param newAddress The new address of the VotingPowerInit
   */
  event VotingPowerInitUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the treasury init is updated.
   * @param oldAddress The old address of the TreasuryInit
   * @param newAddress The new address of the TreasuryInit
   */
  event TreasuryInitUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the governance init is updated.
   * @param oldAddress The old address of the GovernanceInit
   * @param newAddress The new address of the GovernanceInit
   */
  event GovernanceInitUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the sub dao init is updated.
   * @param oldAddress The old address of the SubDAOInit
   * @param newAddress The new address of the SubDAOInit
   */
  event SubDAOInitUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address must be a contract
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice Returns the address of the voting power init contract.
   * @return The address of the VotingPowerInit
   */
  function getVotingPowerInit() external view returns (address);

  /**
   * @notice Returns the address of the treasury init contract.
   * @return The address of the TreasuryInit
   */
  function getTreasuryInit() external view returns (address);

  /**
   * @notice Returns the address of the governance init contract.
   * @return The address of the GovernanceInit
   */
  function getGovernanceInit() external view returns (address);

  /**
   * @notice Returns the address of the sub dao init contract.
   * @return The address of the SubDAOInit
   */
  function getSubDAOInit() external view returns (address);

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Updates the address of the voting power init.
   * @param newVotingPowerInit The address of the new VotingPowerInit
   */
  function setVotingPowerInit(address newVotingPowerInit) external;

  /**
   * @notice Updates the address of the treasury init.
   * @param newTreasuryInit The address of the new TreasuryInit
   */
  function setTreasuryInit(address newTreasuryInit) external;

  /**
   * @notice Updates the address of the governance init.
   * @param newGovernanceInit The address of the new GovernanceInit
   */
  function setGovernanceInit(address newGovernanceInit) external;

  /**
   * @notice Updates the address of the sub dao init.
   * @param newSubDAOInit The address of the new SubDAOInit
   */
  function setSubDAOInit(address newSubDAOInit) external;
}
