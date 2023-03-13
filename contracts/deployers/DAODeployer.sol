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

/**
 * @title DAODeployer - Allows to deploy a new dao diamond contract and set management system and metadata.
 * @author @roleengineer
 */
contract DAODeployer {
  /**
   * @notice Deploys a new dao diamond contract.
   * @param addressesProvider Address of the contract that is a trusted source of facets and init contract addresses.
   * @param daoMetaData Metadata struct which contains strings: daoName, purpose, info and socials.
   * @param msCallData Encoded data which will be used by the management system init contract to initialize state.
   *                   Encoding depends on the respective init function of the init contract and includes selector.
   *                   Management system init contract address is taken from addressesProvider contract.
   * @return Address of the new dao diamond contract.
   */
  function deployDAO(
    address addressesProvider,
    IDAO.DAOMeta memory daoMetaData,
    bytes memory msCallData
  ) external returns (address) {
    HabitatDiamond dao = new HabitatDiamond(addressesProvider, daoMetaData, msCallData);

    IOwnership(address(dao)).transferOwnership(msg.sender);

    return address(dao);
  }
}
