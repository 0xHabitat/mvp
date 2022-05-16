// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibSubDAO} from "../libraries/dao/LibSubDAO.sol";
import {ISubDAO} from "../interfaces/dao/ISubDAO.sol";

contract SubDAOInit {
  // default type
  function initSubDAO(
    string memory subDAOName,
    string memory purpose,
    string memory info,
    string memory socials,
    address mainDAO,
    address addressesProvider
  ) external {
    ISubDAO.SubDAOStorage storage subDAOStruct = LibSubDAO.subDAOStorage();
    subDAOStruct.subDAOName = subDAOName;
    subDAOStruct.purpose = purpose;
    subDAOStruct.info = info;
    subDAOStruct.socials = socials;
    subDAOStruct.mainDAO = msg.sender;
    subDAOStruct.addressesProvider = addressesProvider;
    subDAOStruct.managementSystemPosition = keccak256(bytes.concat(bytes(subDAOName), bytes(purpose), bytes(info), bytes(socials), abi.encode(msg.sender)));
  }
}
