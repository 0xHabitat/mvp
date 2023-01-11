// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {HabitatDiamond} from "../HabitatDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {IDAO} from "../interfaces/dao/IDAO.sol";
import {IManagementSystem} from "../interfaces/dao/IManagementSystem.sol";

interface IOwnership {
  function transferOwnership(address _newOwner) external;
}

contract DAODeployer {

  function deployDAO(
    address addressesProvider,
    IDAO.DAOMeta memory daoMetaData,
    bytes memory msCallData
  ) external returns(address) {
    HabitatDiamond dao = new HabitatDiamond(addressesProvider, daoMetaData, msCallData);

    IOwnership(address(dao)).transferOwnership(msg.sender);

    return address(dao);
  }
}
