// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/DiamondReadable.sol';

contract Readable is DiamondReadable {

  //get cut history ... ?

  receive() external payable {}
}