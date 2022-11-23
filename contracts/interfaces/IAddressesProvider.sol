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
   * @dev Emitted when the default diamond init is updated.
   * @param oldAddress The old address of the DiamondInit
   * @param newAddress The new address of the DiamondInit
   */
  event DiamondInitUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the dao init is updated.
   * @param oldAddress The old address of the DAOInit
   * @param newAddress The new address of the DAOInit
   */
  event DAOInitUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the management system init is updated.
   * @param oldAddress The old address of the ManagementSystemsInit
   * @param newAddress The new address of the ManagementSystemsInit
   */
  event ManagementSystemsInitUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the treasury init is updated.
   * @param oldAddress The old address of the TreasuryInit
   * @param newAddress The new address of the TreasuryInit
   */
  event TreasuryInitUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the DiamondCutFacet is updated.
   * @param oldAddress The old address of the DiamondCutFacet
   * @param newAddress The new address of the DiamondCutFacet
   */
  event DiamondCutFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the OwnershipFacet is updated.
   * @param oldAddress The old address of the OwnershipFacet
   * @param newAddress The new address of the OwnershipFacet
   */
  event OwnershipFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the DiamondLoupeFacet is updated.
   * @param oldAddress The old address of the DiamondLoupeFacet
   * @param newAddress The new address of the DiamondLoupeFacet
   */
  event DiamondLoupeFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the dao viewer facet is updated.
   * @param oldAddress The old address of the DAOViewerFacet
   * @param newAddress The new address of the DAOViewerFacet
   */
  event DAOViewerFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the treasury actions facet is updated.
   * @param oldAddress The old address of the TreasuryActionsFacet
   * @param newAddress The new address of the TreasuryActionsFacet
   */
  event TreasuryActionsFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the treasury viewer facet is updated.
   * @param oldAddress The old address of the TreasuryViewerFacet
   * @param newAddress The new address of the TreasuryViewerFacet
   */
  event TreasuryViewerFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the treasury default callback handler facet is updated.
   * @param oldAddress The old address of the TreasuryDefaultCallbackHandlerFacet
   * @param newAddress The new address of the TreasuryDefaultCallbackHandlerFacet
   */
  event TreasuryDefaultCallbackHandlerFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the voting power specific data facet is updated.
   * @param oldAddress The old address of the VotingPowerSpecificDataFacet
   * @param newAddress The new address of the VotingPowerSpecificDataFacet
   */
  event VotingPowerSpecificDataFacetUpdated(address indexed oldAddress, address indexed newAddress);

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
   * @notice Returns the address of the default diamond init contract.
   * @return The address of the DiamondInit
   */
  function getDiamondInit() external view returns(address);

  /**
   * @notice Returns the address of the dao init contract.
   * @return The address of the DAOInit
   */
  function getDAOInit() external view returns (address);

  /**
   * @notice Returns the address of the dao init contract.
   * @return The address of the ManagementSystemsInit
   */
  function getManagementSystemsInit() external view returns (address);

  /**
   * @notice Returns the address of the treasury init contract.
   * @return The address of the TreasuryInit
   */
  function getTreasuryInit() external view returns (address);

  /**
   * @notice Returns the address and function to call by HabitatDiamondFactory.
   * @return The address and functionSelector to call by HabitatDiamondFactory.
   */
  function getAddressAndFunctionToCall(bytes32 nameOrType) external view returns (address,bytes4);

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
   * @notice Returns the address of the ownership facet contract.
   * @return The address of the OwnershipFacet
   */
  function getOwnershipFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the OwnershipFacet
   */
  function getOwnershipFacet() external view returns (Facet memory);

  /**
   * @notice Returns the address of the diamond loupe facet contract.
   * @return The address of the DiamondLoupeFacet
   */
  function getDiamondLoupeFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the DiamondLoupeFacet
   */
  function getDiamondLoupeFacet() external view returns (Facet memory);

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
   * @notice Returns the address of the treasury actions facet contract.
   * @return The address of the TreasuryActionsFacet
   */
  function getTreasuryActionsFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the TreasuryActionsFacet
   */
  function getTreasuryActionsFacet() external view returns (Facet memory);

  /**
   * @notice Returns the address of the dao viewer facet contract.
   * @return The address of the TreasuryViewerFacet
   */
  function getTreasuryViewerFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the TreasuryViewerFacet
   */
  function getTreasuryViewerFacet() external view returns (Facet memory);

  /**
   * @notice Returns the address of the treasury default callback handler facet contract.
   * @return The address of the TreasuryDefaultCallbackHandlerFacet
   */
  function getTreasuryDefaultCallbackHandlerFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the TreasuryDefaultCallbackHandlerFacet
   */
  function getTreasuryDefaultCallbackHandlerFacet() external view returns (Facet memory);

  /**
   * @notice Returns the address of the voting power specific data facet contract.
   * @return The address of the VotingPowerSpecificDataFacet
   */
  function getVotingPowerSpecificDataFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the VotingPowerSpecificDataFacet
   */
  function getVotingPowerSpecificDataFacet() external view returns (Facet memory);

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Updates the address of the default diamond init.
   * @param newDiamondInit The address of the new DiamondInit
   */
  function setDiamondInit(address newDiamondInit) external;

  /**
   * @notice Updates the address of the dao init.
   * @param newDAOInit The address of the new DAOInit
   */
  function setDAOInit(address newDAOInit) external;

  /**
   * @notice Updates the address of the management system init.
   * @param newManagementSystemsInit The address of the new ManagementSystemsInit
   */
  function setManagementSystemsInit(address newManagementSystemsInit) external;

  /**
   * @notice Updates the address of the treasury init.
   * @param newTreasuryInit The address of the new TreasuryInit
   */
  function setTreasuryInit(address newTreasuryInit) external;

  /**
   * @notice Updates the address of the diamond cut facet.
   * @param newDiamondCutFacet The address of the new DiamondCutFacet
   */
  function setDiamondCutFacet(address newDiamondCutFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the ownership facet.
   * @param newOwnershipFacet The address of the new OwnershipFacet
   */
  function setOwnershipFacet(address newOwnershipFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the diamond loupe facet.
   * @param newDiamondLoupeFacet The address of the new DiamondLoupeFacet
   */
  function setDiamondLoupeFacet(address newDiamondLoupeFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the DAO viewer facet.
   * @param newDAOViewerFacet The address of the new DAOViewerFacet
   */
  function setDAOViewerFacet(address newDAOViewerFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the treasury actions facet.
   * @param newTreasuryActionsFacet The address of the new TreasuryActionsFacet
   */
  function setTreasuryActionsFacet(address newTreasuryActionsFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the treasury viewer facet.
   * @param newTreasuryViewerFacet The address of the new TreasuryViewerFacet
   */
  function setTreasuryViewerFacet(address newTreasuryViewerFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the treasury default callback handler facet.
   * @param newTreasuryDefaultCallbackHandlerFacet The address of the new TreasuryDefaultCallbackHandlerFacet
   */
  function setTreasuryDefaultCallbackHandlerFacet(address newTreasuryDefaultCallbackHandlerFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the voting power specific data facet.
   * @param newVotingPowerSpecificDataFacet The address of the new VotingPowerSpecificDataFacet
   */
  function setVotingPowerSpecificDataFacet(address newVotingPowerSpecificDataFacet, bytes4[] memory selectors) external;
}
