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

  function deployDAOMS5(
    address addressesProvider,
    IDAO.DAOMeta memory daoMetaData,
    IManagementSystem.DecisionType[] memory decisionTypes,
    address[] memory deciders
  ) external returns(address) {
    HabitatDiamond dao = new HabitatDiamond(address(this), addressesProvider, daoMetaData);

    // make management system init
    IDiamondCut.FacetCut[] memory emptyCut;
    address managementSystemInit = IAddressesProvider(addressesProvider).getManagementSystemsInit();
    bytes memory msCallData = abi.encodeWithSignature(
      "initManagementSystems5(uint8[],address[])",
      decisionTypes,
      deciders
    );
    IDiamondCut(address(dao)).diamondCut(emptyCut, managementSystemInit, msCallData);

    IOwnership(address(dao)).transferOwnership(msg.sender);

    return address(dao);
  }
}
