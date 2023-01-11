// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDAOStorage} from "../libraries/dao/LibDAOStorage.sol";
import {IDAO} from "../interfaces/dao/IDAO.sol";


contract DAOInit {
  // default type
  function initDAO(
    string memory daoName,
    string memory purpose,
    string memory info,
    string memory socials,
    address addressesProvider
  ) external {
    IDAO.DAOStorage storage daoStruct = LibDAOStorage.daoStorage();
    daoStruct.daoName = daoName;
    daoStruct.purpose = purpose;
    daoStruct.info = info;
    daoStruct.socials = socials;
    daoStruct.addressesProvider = addressesProvider;
  }
}
