// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {DAOInit} from "../upgradeInitializers/DAOInit.sol";

contract DAOInitTest is DAOInit {
  bytes32 constant DAO_STORAGE_POSITION = keccak256("habitat.diamond.standard.dao.storage");

  struct DAOStorage {
    string daoName;
    string purpose;
    string info;
    string socials;
    address addressesProvider;
    address[] createdSubDAOs;
    string newString;
  }

  function daoStorage() internal pure returns (DAOStorage storage ds) {
    bytes32 position = DAO_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function initNewStringInDAOStorage(string memory _newString) external {
    DAOStorage storage daoStruct = daoStorage();
    daoStruct.newString = _newString;
  }
}
