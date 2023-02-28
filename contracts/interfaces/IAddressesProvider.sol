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
   * @dev Emitted when the specific data init is updated.
   * @param oldAddress The old address of the SpecificDataInit
   * @param newAddress The new address of the SpecificDataInit
   */
  event SpecificDataInitUpdated(address indexed oldAddress, address indexed newAddress);

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
   * @dev Emitted when the module viewer facet is updated.
   * @param oldAddress The old address of the ModuleViewerFacet
   * @param newAddress The new address of the ModuleViewerFacet
   */
  event ModuleViewerFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the management system facet is updated.
   * @param oldAddress The old address of the ManagementSystemFacet
   * @param newAddress The new address of the ManagementSystemFacet
   */
  event ManagementSystemFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the module manager facet is updated.
   * @param oldAddress The old address of the ModuleManagerFacet
   * @param newAddress The new address of the ModuleManagerFacet
   */
  event ModuleManagerFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the governance facet is updated.
   * @param oldAddress The old address of the GovernanceFacet
   * @param newAddress The new address of the GovernanceFacet
   */
  event GovernanceFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the treasury actions facet is updated.
   * @param oldAddress The old address of the TreasuryActionsFacet
   * @param newAddress The new address of the TreasuryActionsFacet
   */
  event TreasuryActionsFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the treasury default callback handler facet is updated.
   * @param oldAddress The old address of the TreasuryDefaultCallbackHandlerFacet
   * @param newAddress The new address of the TreasuryDefaultCallbackHandlerFacet
   */
  event TreasuryDefaultCallbackHandlerFacetUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the specific data facet is updated.
   * @param oldAddress The old address of the SpecificDataFacet
   * @param newAddress The new address of the SpecificDataFacet
   */
  event SpecificDataFacetUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address must be a contract
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice Returns a bool that describes facet address existence.
   * @dev It returns false if there is no registered facet address
   * @param facet Facet address
   * @return The bool that describes facet address existence
   */
  function facetAddressExist(address facet) external view returns (bool);

  /**
   * @notice Returns an array of facet selectors by facet address.
   * @dev It returns empty array if there is no registered selectors with the given facet
   * @param facet The facet address
   * @return An array of the registered selectors for the specified facet
   */
  function getSelectors(address facet) external view returns (bytes4[] memory);

  /**
   * @notice Returns an address of init contract for facet address.
   * @dev It returns address(0) if there is no registered init for the given facet
   * @param facet The facet address
   * @return An address of init contract for the specified facet address
   */
  function getInitForFacet(address facet) external view returns (address);

  /**
   * @notice Temporary init contract.
   * @return The address of the RemoveDiamondCutInit
   */
  function getRemoveDiamondCutInit() external view returns (address);

  /**
   * @notice Returns the address of the default diamond init contract.
   * @return The address of the DiamondInit
   */
  function getDiamondInit() external view returns (address);

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
   * @notice Returns the address of the specific data init contract.
   * @return The address of the SpecificDataInit
   */
  function getSpecificDataInit() external view returns (address);

  /**
   * @notice Returns the address and function to call by HabitatDiamondFactory.
   * @return The address and functionSelector to call by HabitatDiamondFactory.
   */
  function getAddressAndFunctionToCall(bytes32 nameOrType) external view returns (address, bytes4);

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
   * @notice Returns the address of the Module viewer facet contract.
   * @return The address of the ModuleViewerFacet
   */
  function getModuleViewerFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the ModuleViewerFacet
   */
  function getModuleViewerFacet() external view returns (Facet memory);

  /**
   * @notice Returns the address of the management system facet contract.
   * @return The address of the ManagementSystemFacet
   */
  function getManagementSystemFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the ManagementSystemFacet
   */
  function getManagementSystemFacet() external view returns (Facet memory);

  /**
   * @notice Returns the address of the governance facet contract.
   * @return The address of the GovernanceFacet
   */
  function getGovernanceFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the GovernanceFacet
   */
  function getGovernanceFacet() external view returns (Facet memory);

  /**
   * @notice Returns the address of the module manager facet contract.
   * @return The address of the ModuleManagerFacet
   */
  function getModuleManagerFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the ModuleManagerFacet
   */
  function getModuleManagerFacet() external view returns (Facet memory);

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
   * @notice Returns the address of the specific data facet contract.
   * @return The address of the SpecificDataFacet
   */
  function getSpecificDataFacetAddress() external view returns (address);

  /**
   * @notice Returns Facet (facet address and an array of the facet selectors).
   * @return Facet struct of the SpecificDataFacet
   */
  function getSpecificDataFacet() external view returns (Facet memory);

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Temporary init.
   */
  function setRemoveDiamondCutInit(address init) external;

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
   * @notice Updates the address of the specific data init.
   * @param newSpecificDataInit The address of the new SpecificDataInit
   */
  function setSpecificDataInit(address newSpecificDataInit) external;

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
   * @notice Updates the address of the Module viewer facet.
   * @param newModuleViewerFacet The address of the new ModuleViewerFacet
   */
  function setModuleViewerFacet(address newModuleViewerFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the management system facet.
   * @param newManagementSystemFacet The address of the new ManagementSystemFacet
   */
  function setManagementSystemFacet(
    address newManagementSystemFacet,
    bytes4[] memory selectors
  ) external;

  /**
   * @notice Updates the address of the module manager facet.
   * @param newModuleManagerFacet The address of the new ModuleManagerFacet
   */
  function setModuleManagerFacet(address newModuleManagerFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the governance facet.
   * @param newGovernanceFacet The address of the new GovernanceFacet
   */
  function setGovernanceFacet(address newGovernanceFacet, bytes4[] memory selectors) external;

  /**
   * @notice Updates the address of the treasury actions facet.
   * @param newTreasuryActionsFacet The address of the new TreasuryActionsFacet
   */
  function setTreasuryActionsFacet(
    address newTreasuryActionsFacet,
    bytes4[] memory selectors
  ) external;

  /**
   * @notice Updates the address of the treasury default callback handler facet.
   * @param newTreasuryDefaultCallbackHandlerFacet The address of the new TreasuryDefaultCallbackHandlerFacet
   */
  function setTreasuryDefaultCallbackHandlerFacet(
    address newTreasuryDefaultCallbackHandlerFacet,
    bytes4[] memory selectors
  ) external;

  /**
   * @notice Updates the address of the specific data facet.
   * @param newSpecificDataFacet The address of the new SpecificDataFacet
   */
  function setSpecificDataFacet(address newSpecificDataFacet, bytes4[] memory selectors) external;
}
