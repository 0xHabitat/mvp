// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDAO} from "../../interfaces/dao/IDAO.sol";
import {LibDAOStorage} from "../../libraries/dao/LibDAOStorage.sol";

contract DAOViewerFacet {

  function getDAOName() external view returns (string memory) {
    return LibDAOStorage._getDAOName();
  }

  function getDAOPurpose() external view returns (string memory) {
    return LibDAOStorage._getDAOPurpose();
  }

  function getDAOInfo() external view returns (string memory) {
    return LibDAOStorage._getDAOInfo();
  }

  function getDAOSocials() external view returns (string memory) {
    return LibDAOStorage._getDAOSocials();
  }

  function hasSubDAOs() external view returns (bool) {

  }

  function getCreatedSubDAOs() external view returns (address[] memory) {

  }

  function isMainDAOFor(address _subDAO) external view returns (bool) {

  }

  function getManagementSystemsPosition() external view returns (bytes32) {
    return LibDAOStorage._getManagementSystemsPosition();
  }
}