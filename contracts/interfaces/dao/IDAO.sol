// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDAO {
  struct DAOStorage {
    string daoName;
    string purpose;
    string info;
    string socials;
    address addressesProvider;
    address[] createdSubDAOs;
  }

  struct DAOMeta {
    string daoName;
    string purpose;
    string info;
    string socials;
  }
}
