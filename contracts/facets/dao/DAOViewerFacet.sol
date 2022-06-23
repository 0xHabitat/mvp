// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDAO} from "../../interfaces/dao/IDAO.sol";
import {LibDAOStorage} from "../../libraries/dao/LibDAOStorage.sol";
import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";

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
/*
  function getGovernanceVotingSystem() external view returns (IManagementSystem.VotingSystem) {

  }

  function getTreasuryVotingSystem() external view returns (IManagementSystem.VotingSystem) {

  }

  function getSubDAOCreationVotingSystem() external view returns (IManagementSystem.VotingSystem) {

  }

  function getVotingPowerManager() external view returns (address) {

  }

  function getGovernanceSigners() external view returns (address[] memory) {

  }

  function getTreasurySigners() external view returns (address[] memory) {

  }

  function getSubDAOCreationSigners() external view returns (address[] memory) {

  }

  function isGovernanceSigner(address _signer) external view returns (bool) {

  }

  function isTreasurySigner(address _signer) external view returns (bool) {

  }

  function isSubDAOCreationSigner(address _signer) external view returns (bool) {

  }
*/
}
