// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title IAddressesProvider
 * @author HabitatDAO
 * @notice Defines the basic interface for an Addresses Provider.
 **/
interface IAddressesProvider {
  struct Facet {
    address facetAddress;
    bytes4[] functionSelectors;
  }

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
   * @dev Emitted when the dao init is updated.
   * @param oldAddress The old address of the DAOInit
   * @param newAddress The new address of the DAOInit
   */
  event DAOInitUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the sub dao init is updated.
   * @param oldAddress The old address of the SubDAOInit
   * @param newAddress The new address of the SubDAOInit
   */
  event SubDAOInitUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the WETH is updated.
   * @param oldAddress The old address of the WETH
   * @param newAddress The new address of the WETH
   */
  event WETHUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the UniswapV2Factory is updated.
   * @param oldAddress The old address of the UniswapV2Factory
   * @param newAddress The new address of the UniswapV2Factory
   */
  event UniswapV2FactoryUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the SushiV2Factory is updated.
   * @param oldAddress The old address of the SushiV2Factory
   * @param newAddress The new address of the SushiV2Factory
   */
  event SushiV2FactoryUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the HabitatDiamondFactory is updated.
   * @param oldAddress The old address of the HabitatDiamondFactory
   * @param newAddress The new address of the HabitatDiamondFactory
   */
  event HabitatDiamondFactoryUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the DiamondCutFacet is updated.
   * @param oldAddress The old address of the DiamondCutFacet
   * @param newAddress The new address of the DiamondCutFacet
   */
  event DiamondCutFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the dao viewer facet is updated.
   * @param oldAddress The old address of the DAOViewerFacet
   * @param newAddress The new address of the DAOViewerFacet
   */
  event DAOViewerFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the storage writer facet is updated.
   * @param oldAddress The old address of the StorageWriterFacet
   * @param newAddress The new address of the StorageWriterFacet
   */
  event StorageWriterFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address must be a contract
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice Returns an array of facet selectors by facet address.
   * @dev It returns empty array if there is no registered selectors with the given facet
   * @param facet The facet address
   * @return An array of the registered selectors for the specified facet
   */
  function getSelectors(address facet) external view returns (bytes4[] memory);

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
   * @notice Returns the address of the dao init contract.
   * @return The address of the DAOInit
   */
  function getDAOInit() external view returns (address);

  /**
   * @notice Returns the address of the sub dao init contract.
   * @return The address of the SubDAOInit
   */
  function getSubDAOInit() external view returns (address);

  // the getters below can be adjusted
  /**
   * @notice Returns the address of the only owner init contract.
   * @return The address of the OnlyOwnerInit
   */
  function getOnlyOwnerInit() external view returns (address);

  /**
   * @notice Returns the address of the signers init contract.
   * @return The address of the SignersInit
   */
  function getSignersInit() external view returns (address);

  /**
   * @notice Returns the address and function to call by HabitatDiamondFactory.
   * @return The address and functionSelector to call by HabitatDiamondFactory.
   */
  function getAddressAndFunctionToCall(bytes32 nameOrType) external view returns (address,bytes4);

  // the getters above can be adjusted

  /**
   * @notice Returns the address of the WETH contract.
   * @return The address of the WETH
   */
  function getWETH() external view returns (address);

  /**
   * @notice Returns the address of the UniswapV2Factory contract.
   * @return The address of the UniswapV2Factory
   */
  function getUniswapV2Factory() external view returns (address);

  /**
   * @notice Returns the address of the SushiV2Factory contract.
   * @return The address of the SushiV2Factory
   */
  function getSushiV2Factory() external view returns (address);

  /**
   * @notice Returns the address of the HabitatDiamondFactory contract.
   * @return The address of the HabitatDiamondFactory
   */
  function getHabitatDiamondFactory() external view returns (address);

  /**
   * @notice Returns the address of the diamond cut facet contract.
   * @return The address of the DiamondCutFacet
   */
  function getDiamondCutFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the DiamondCutFacet
   */
  function getDiamondCutFacet() external view returns (Facet memory);

  /**
   * @notice Returns the address of the voting power facet contract.
   * @return The address of the VotingPowerFacet
   */
  function getVotingPowerFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the VotingPower
   */
  function getVotingPowerFacet() external view returns (Facet memory);

  /**
   * @notice Returns the address of the dao viewer facet contract.
   * @return The address of the DAOViewerFacet
   */
  function getDAOViewerFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the DAOViewerFacet
   */
  function getDAOViewerFacet() external view returns (Facet memory);

  /**
   * @notice Returns the address of the storage writer facet contract.
   * @return The address of the StorageWriterFacet
   */
  function getStorageWriterFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the StorageWriterFacet
   */
  function getStorageWriterFacet() external view returns (Facet memory);

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
   * @notice Updates the address of the dao init.
   * @param newDAOInit The address of the new DAOInit
   */
  function setDAOInit(address newDAOInit) external;

  /**
   * @notice Updates the address of the sub dao init.
   * @param newSubDAOInit The address of the new SubDAOInit
   */
  function setSubDAOInit(address newSubDAOInit) external;

  /**
   * @notice Updates the address of the WETH.
   * @param newWETH The address of the new WETH
   */
  function setWETH(address newWETH) external;

  /**
   * @notice Updates the address of the UniswapV2Factory.
   * @param newUniswapV2Factory The address of the new UniswapV2Factory
   */
  function setUniswapV2Factory(address newUniswapV2Factory) external;

  /**
   * @notice Updates the address of the SushiV2Factory.
   * @param newSushiV2Factory The address of the new SushiV2Factory
   */
  function setSushiV2Factory(address newSushiV2Factory) external;

  /**
   * @notice Updates the address of the HabitatDiamondFactory.
   * @param newHabitatDiamondFactory The address of the new HabitatDiamondFactory
   */
  function setHabitatDiamondFactory(address newHabitatDiamondFactory) external;

  /**
   * @notice Updates the address of the diamond cut facet.
   * @param newDiamondCutFacet The address of the new DiamondCutFacet
   */
  function setDiamondCutFacet(address newDiamondCutFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the voting power facet.
   * @param newVotingPowerFacet The address of the new VotingPowerFacet
   */
  function setVotingPowerFacet(address newVotingPowerFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the DAO viewer facet.
   * @param newDAOViewerFacet The address of the new DAOViewerFacet
   */
  function setDAOViewerFacet(address newDAOViewerFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the Storage Writer facet.
   * @param newStorageWriterFacet The address of the new StorageWriterFacet
   */
  function setStorageWriterFacet(address newStorageWriterFacet, bytes4[] memory selectors) external;
}
