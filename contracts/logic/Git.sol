// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondWritable } from '@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol';
import { MinimalProxyFactory } from '@solidstate/contracts/factory/MinimalProxyFactory.sol';

import { IGit } from './IGit.sol';
import { Storage } from '../storage/Storage.sol';
import { Upgrade, IUpgrade } from '../external/Upgrade.sol';

contract Git is IGit, MinimalProxyFactory {
  using Storage for Storage.Layout;

  address immutable public model;

  constructor (IDiamondWritable.FacetCut[] memory _cuts) {
    Upgrade instance = new Upgrade();
    model = address(instance);
    IUpgrade(model).set(_cuts, address(0), '');
  }  
  
  /**
   * @inheritdoc IGit
   */
  function commit(
    string calldata name,
    IDiamondWritable.FacetCut[] calldata cuts,
    address target,
    bytes calldata data
  ) external returns (address) {
    address instance = _deployMinimalProxy(model);
    IUpgrade(instance).set(cuts, target, data);
    Storage.layout().commit(msg.sender, name, instance);
    return instance;
  }

  /**
   * @inheritdoc IGit
   */
  function latest(
    address owner, 
    string memory name
  ) external view returns (address) {
    return Storage.layout().latest(owner, name);
  }
}