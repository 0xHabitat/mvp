// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDAOStorage} from "../libraries/dao/LibDAOStorage.sol";
import {IDAO} from "../interfaces/dao/IDAO.sol";

/**
 * @title DAOInit - Init contract that initialize DAO metadata and addresses provider.
 * @author @roleengineer
 */
contract DAOInit {
  /**
   * @notice Method initiates DAO metadata and addresses provider.
   * @param daoName The name of the DAO.
   * @param purpose String describes the DAO purpose.
   * @param info String describes the DAO information.
   * @param socials String describes the DAO socials, like website or social account url.
   * @param addressesProvider Address of the contract, that is a DAO trusted source of facets and init contracts.
   */
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
