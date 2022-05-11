// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ISubDAO} from "../../interfaces/dao/ISubDAO.sol";
import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "./LibManagementSystem.sol";

library LibSubDAO {
  bytes32 constant SUB_DAO_STORAGE_POSITION = keccak256("habitat.diamond.standard.subdao.storage");

  /*
struct SubDAOStorage {
  string subDAOName;
  string purpose;
  string info;
  string socials;
  address mainDAO;
  address[] createdSubDAOs;
  bytes32 managementSystemPosition;
}
*/
  function subDAOStorage() internal pure returns (ISubDAO.SubDAOStorage storage sds) {
    bytes32 position = SUB_DAO_STORAGE_POSITION;
    assembly {
      sds.slot := position
    }
  }

  function _getSubDAOName() internal view returns (string storage subDAOName) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    subDAOName = sds.subDAOName;
  }

  function _getSubDAOPurpose() internal view returns (string storage subDAOPurpose) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    subDAOPurpose = sds.purpose;
  }

  function _getSubDAOInfo() internal view returns (string storage subDAOInfo) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    subDAOInfo = sds.info;
  }

  function _getSubDAOSocials() internal view returns (string storage subDAOSocials) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    subDAOSocials = sds.info;
  }

  function _getMainDAO() internal view returns (address) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    return sds.mainDAO;
  }

  function _hasSubDAOs() internal view returns (bool) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    return sds.createdSubDAOs.length > 0;
  }

  function _getCreatedSubDAOs() internal view returns (address[] storage) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    return sds.createdSubDAOs;
  }

  function _isMainDAOFor(address _subDAO) internal view returns (bool) {
    require(_hasSubDAOs(), "SubDAO has not created subDAOs yet.");
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    // maybe better use Gnosis data structure (nested array) instead of an array
    for (uint256 i = 0; i < sds.createdSubDAOs.length; i++) {
      if (sds.createdSubDAOs[i] == _subDAO) {
        return true;
      }
    }
    return false;
  }

  function _isSubDAOOf(address _mainDAO) internal view returns (bool) {
    return _mainDAO == _getMainDAO();
  }

  function _getManagementSystem()
    internal
    view
    returns (IManagementSystem.ManagementSystem storage ms)
  {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    ms = LibManagementSystem._getManagementSystemByPosition(sds.managementSystemPosition);
  }

  function _getGovernanceVotingSystem() internal view returns (IManagementSystem.VotingSystem gvs) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    gvs = LibManagementSystem._getGovernanceVotingSystem(sds.managementSystemPosition);
  }

  function _getTreasuryVotingSystem() internal view returns (IManagementSystem.VotingSystem tvs) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    tvs = LibManagementSystem._getTreasuryVotingSystem(sds.managementSystemPosition);
  }

  function _getSubDAOCreationVotingSystem()
    internal
    view
    returns (IManagementSystem.VotingSystem sdcvs)
  {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    sdcvs = LibManagementSystem._getSubDAOCreationVotingSystem(sds.managementSystemPosition);
  }

  function _getVotingPowerManager() internal view returns (address vpm) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    vpm = LibManagementSystem._getVotingPowerManager(sds.managementSystemPosition);
  }

  function _getGovernanceERC20Token() internal view returns (address gerc20t) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    gerc20t = LibManagementSystem._getGovernanceERC20Token(sds.managementSystemPosition);
  }

  function _getGovernanceSigners() internal view returns (address[] storage gs) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    gs = LibManagementSystem._getGovernanceSigners(sds.managementSystemPosition);
  }

  function _getTreasurySigners() internal view returns (address[] storage ts) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    ts = LibManagementSystem._getTreasurySigners(sds.managementSystemPosition);
  }

  function _getSubDAOCreationSigners() internal view returns (address[] storage sdcs) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    sdcs = LibManagementSystem._getSubDAOCreationSigners(sds.managementSystemPosition);
  }

  function _isGovernanceSigner(address _signer) internal view returns (bool) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    return LibManagementSystem._isGovernanceSigner(sds.managementSystemPosition, _signer);
  }

  function _isTreasurySigner(address _signer) internal view returns (bool) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    return LibManagementSystem._isTreasurySigner(sds.managementSystemPosition, _signer);
  }

  function _isSubDAOCreationSigner(address _signer) internal view returns (bool) {
    ISubDAO.SubDAOStorage storage sds = subDAOStorage();
    return LibManagementSystem._isSubDAOCreationSigner(sds.managementSystemPosition, _signer);
  }
}
