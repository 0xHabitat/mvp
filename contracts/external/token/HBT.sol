// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HBT is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint totalSupply,
    address distributor
  ) ERC20(name, symbol) {
    _mint(distributor, totalSupply);
  }
}
