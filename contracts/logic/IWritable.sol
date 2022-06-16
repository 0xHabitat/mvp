// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondWritable } from '@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol';

/**
 * @title Universally Compatible Diamond Cut Facet w/ Git Control -- by @tjvsx
 * This contract is to be used as a facet of an EIP2535 'Diamond' proxy. It provides multiple 
 * methods for upgrading a diamond, each of which serve a specific contract user type. Additionally,
 * this contract is integrated with a git system that stores the upgrades in another diamond whose
 * sole purpose is to act as an immutable on-chain open-source upgrade repository.
 */
interface IWritable is IDiamondWritable {

  /**
   * @notice perform a standard diamondCut and add to one of your git repos
   * @dev call externally from single-wallet diamond
   */
  function cutAndCommit(
      string calldata name,
      FacetCut[] calldata facetCuts,
      address target,
      bytes calldata data
  ) external;

  /**
   * @notice update a contract package to the latest version
   * @dev call externally from single-wallet diamond
   * @
   */
  function update(address owner, string memory name) external;

}
