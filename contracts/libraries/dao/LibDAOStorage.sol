// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDAO} from "../../interfaces/dao/IDAO.sol";
import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "./LibManagementSystem.sol";

library LibDAOStorage {
  bytes32 constant DAO_STORAGE_POSITION = keccak256("habitat.diamond.standard.dao.storage");

  /*
struct DAOStorage {
  string daoName;
  string purpose;
  string info;
  string socials;
  bytes32 managementSystemPosition;
  address[] createdSubDAOs;
}
*/
  function daoStorage() internal pure returns (IDAO.DAOStorage storage ds) {
    bytes32 position = DAO_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function _getDAOName() internal view returns (string storage daoName) {
    IDAO.DAOStorage storage ds = daoStorage();
    daoName = ds.daoName;
  }

  function _getDAOPurpose() internal view returns (string storage daoPurpose) {
    IDAO.DAOStorage storage ds = daoStorage();
    daoPurpose = ds.purpose;
  }

  function _getDAOInfo() internal view returns (string storage daoInfo) {
    IDAO.DAOStorage storage ds = daoStorage();
    daoInfo = ds.info;
  }

  function _getDAOSocials() internal view returns (string storage daoSocials) {
    IDAO.DAOStorage storage ds = daoStorage();
    daoSocials = ds.socials;
  }

  function _hasSubDAOs() internal view returns (bool) {
    IDAO.DAOStorage storage ds = daoStorage();
    return ds.createdSubDAOs.length > 0;
  }

  function _getCreatedSubDAOs() internal view returns (address[] storage) {
    IDAO.DAOStorage storage ds = daoStorage();
    return ds.createdSubDAOs;
  }

  function _isMainDAOFor(address _subDAO) internal view returns (bool) {
    require(_hasSubDAOs(), "MainDAO has not created subDAOs yet.");
    IDAO.DAOStorage storage ds = daoStorage();
    for (uint256 i = 0; i < ds.createdSubDAOs.length; i++) {
      if (ds.createdSubDAOs[i] == _subDAO) {
        return true;
      }
    }
    return false;
  }

  function _getManagementSystem()
    internal
    view
    returns (IManagementSystem.ManagementSystem storage ms)
  {
    IDAO.DAOStorage storage ds = daoStorage();
    ms = LibManagementSystem._getManagementSystemByPosition(ds.managementSystemPosition);
  }

  function _getGovernanceVotingSystem() internal view returns (IManagementSystem.VotingSystem gvs) {
    IDAO.DAOStorage storage ds = daoStorage();
    gvs = LibManagementSystem._getGovernanceVotingSystem(ds.managementSystemPosition);
  }

  function _getTreasuryVotingSystem() internal view returns (IManagementSystem.VotingSystem tvs) {
    IDAO.DAOStorage storage ds = daoStorage();
    tvs = LibManagementSystem._getTreasuryVotingSystem(ds.managementSystemPosition);
  }

  function _getSubDAOCreationVotingSystem()
    internal
    view
    returns (IManagementSystem.VotingSystem sdcvs)
  {
    IDAO.DAOStorage storage ds = daoStorage();
    sdcvs = LibManagementSystem._getSubDAOCreationVotingSystem(ds.managementSystemPosition);
  }

  function _getVotingPowerManager() internal view returns (address vpm) {
    IDAO.DAOStorage storage ds = daoStorage();
    vpm = LibManagementSystem._getVotingPowerManager(ds.managementSystemPosition);
  }

  function _getGovernanceERC20Token() internal view returns (address gerc20t) {
    IDAO.DAOStorage storage ds = daoStorage();
    gerc20t = LibManagementSystem._getGovernanceERC20Token(ds.managementSystemPosition);
  }

  function _getGovernanceSigners() internal view returns (address[] storage gs) {
    IDAO.DAOStorage storage ds = daoStorage();
    gs = LibManagementSystem._getGovernanceSigners(ds.managementSystemPosition);
  }

  function _getTreasurySigners() internal view returns (address[] storage ts) {
    IDAO.DAOStorage storage ds = daoStorage();
    ts = LibManagementSystem._getTreasurySigners(ds.managementSystemPosition);
  }

  function _getSubDAOCreationSigners() internal view returns (address[] storage sdcs) {
    IDAO.DAOStorage storage ds = daoStorage();
    sdcs = LibManagementSystem._getSubDAOCreationSigners(ds.managementSystemPosition);
  }

  function _isGovernanceSigner(address _signer) internal view returns (bool) {
    IDAO.DAOStorage storage ds = daoStorage();
    return LibManagementSystem._isGovernanceSigner(ds.managementSystemPosition, _signer);
  }

  function _isTreasurySigner(address _signer) internal view returns (bool) {
    IDAO.DAOStorage storage ds = daoStorage();
    return LibManagementSystem._isTreasurySigner(ds.managementSystemPosition, _signer);
  }

  function _isSubDAOCreationSigner(address _signer) internal view returns (bool) {
    IDAO.DAOStorage storage ds = daoStorage();
    return LibManagementSystem._isSubDAOCreationSigner(ds.managementSystemPosition, _signer);
  }
}
