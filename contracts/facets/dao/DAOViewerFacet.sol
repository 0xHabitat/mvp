// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDAOStorage} from "../../libraries/dao/LibDAOStorage.sol";

/**
 * @title DAOViewerFacet - Facet provides view functions related to the DAO metadata,
 *                         addresses provider and sub DAOs.
 * @author @roleengineer
 */
contract DAOViewerFacet {
  /**
   * @notice Returns DAO name.
   */
  function getDAOName() external view returns (string memory) {
    return LibDAOStorage._getDAOName();
  }

  /**
   * @notice Returns DAO purpose.
   */
  function getDAOPurpose() external view returns (string memory) {
    return LibDAOStorage._getDAOPurpose();
  }

  /**
   * @notice Returns DAO info.
   */
  function getDAOInfo() external view returns (string memory) {
    return LibDAOStorage._getDAOInfo();
  }

  /**
   * @notice Returns DAO socials.
   */
  function getDAOSocials() external view virtual returns (string memory) {
    return LibDAOStorage._getDAOSocials();
  }

  /**
   * @notice Returns DAO addresses provider.
   * @dev Address of the contract that is a trusted source of facets and init contract addresses.
   */
  function getDAOAddressesProvider() external view returns (address) {
    return LibDAOStorage._getDAOAddressesProvider();
  }

  function hasSubDAOs() external view returns (bool) {}

  function getCreatedSubDAOs() external view returns (address[] memory) {}

  function isMainDAOFor(address _subDAO) external view returns (bool) {}
}
