// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PeaceTest is ERC20 {

  address public dao;

  constructor(
    string memory name,
    string memory symbol,
    address _dao
  ) ERC20(name, symbol) {
    dao = _dao;
  }

  function mintPeaceMax500(
    address[] memory _receivers,
    uint256[] memory _amounts
  ) external returns(bool) {
    require(msg.sender == dao, "Only dao can mint");
    uint256 number = _receivers.length;
    require(number <= 500 && number == _amounts.length, "Max 500. Check the arrays length.");
    for (uint256 i = 0; i < number; i++) {
      _mint(_receivers[i], _amounts[i]);
    }
    return true;
  }
}
