// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISubDAO {
  struct SubDAOStorage {
    string subDAOName;
    string purpose;
    string info;
    string socials;
    address mainDAO;
    address[] createdSubDAOs;
  }

  function getSubDAOName() external view returns (string memory);

  function getSubDAOPurpose() external view returns (string memory);

  function getSubDAOInfo() external view returns (string memory);

  function getSubDAOSocials() external view returns (string memory);

  function getMainDAO() external view returns (address);

  function hasSubDAOs() external view returns (bool);

  function getCreatedSubDAOs() external view returns (address[] memory);

  function isSubDAOOf(address _mainDAO) external view returns (bool);

  function isMainDAOFor(address _subDAO) external view returns (bool);
}
