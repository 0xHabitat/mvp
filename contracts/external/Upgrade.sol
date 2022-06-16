// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondWritable } from '@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol';
import { DiamondBaseStorage } from '@solidstate/contracts/proxy/diamond/base/DiamondBaseStorage.sol';

import { IUpgrade } from './IUpgrade.sol';
import { Storage } from '../storage/Storage.sol';

contract Upgrade {
  using DiamondBaseStorage for DiamondBaseStorage.Layout;
  using Storage for Storage.Layout;

  bool private registered;

  struct Cut {
    address target;
    IDiamondWritable.FacetCutAction action;
    bytes4[] selectors;
  }

  Cut[] public cuts;
  address public target;
  bytes public data;

  function set(
    IDiamondWritable.FacetCut[] memory _cuts,
    address _target,
    bytes memory _data
  )
  external {
    require(!registered, 'Upgrade: already registered.');
    //store cut
    IDiamondWritable.FacetCut memory c;
    for (uint256 i; i < _cuts.length; i++) { 
      c = _cuts[i];
      cuts.push(Cut(c.target, c.action, c.selectors));
    }
    target = _target;
    data = _data;
    registered = true;
  }

  function get() external view returns (
    IDiamondWritable.FacetCut[] memory, 
    address, 
    bytes memory
  ) {
    IDiamondWritable.FacetCut[] memory _cuts = new IDiamondWritable.FacetCut[](cuts.length);
    for (uint i; i < _cuts.length; i++) {
      _cuts[i] = IDiamondWritable.FacetCut({
        target: cuts[i].target,
        action: cuts[i].action,
        selectors: cuts[i].selectors
      });
    }
    return(_cuts, target, data);
  }
  
}