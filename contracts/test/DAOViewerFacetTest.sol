// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {DAOViewerFacet} from "../facets/dao/DAOViewerFacet.sol";

contract DAOViewerFacetTest is DAOViewerFacet {
  bytes32 constant DAO_STORAGE_POSITION = keccak256("habitat.diamond.standard.dao.storage");

  struct DAOStorage {
    string daoName;
    string purpose;
    string info;
    string socials;
    address addressesProvider;
    address[] createdSubDAOs;
    string newString;
  }

  function daoStorage() internal pure returns (DAOStorage storage ds) {
    bytes32 position = DAO_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function getDAOSocials() external view override returns (string memory) {
    return "new dao socials";
  }

  function newDAOViewerFunction1() external view returns(uint256) {
    return 256;
  }

  function newDAOViewerFunction2() external view returns(string memory) {
    return "some another new string";
  }

  function readNewDAOState() external view returns(string memory) {
    DAOStorage storage ds = daoStorage();
    return ds.newString;
  }
}
