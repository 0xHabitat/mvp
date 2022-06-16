// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { DiamondWritable } from '@solidstate/contracts/proxy/diamond/writable/DiamondWritable.sol';
import { Library } from './libraries/Library.sol';
import { IWritable } from './IWritable.sol';
import { IGit } from './IGit.sol';

contract Writable is IWritable, DiamondWritable {

  address public immutable diamond;

  constructor(address _diamond) {
    diamond = _diamond;
  }

  function cutAndCommit(
      string calldata name,
      FacetCut[] calldata facetCuts,
      address target,
      bytes calldata data
  ) external onlyOwner {
      Library._cut(facetCuts, target, data);
      IGit(diamond).commit(name, facetCuts, target, data);
  }

  function update(address account, string memory name) external onlyOwner {
    address upgrade = IGit(diamond).latest(account, name);
    Library._upgrade(upgrade);
  }

}