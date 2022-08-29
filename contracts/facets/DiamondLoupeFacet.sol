// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/DiamondReadable.sol';

contract DiamondLoupeFacet is DiamondReadable {
  receive() external payable {}
}