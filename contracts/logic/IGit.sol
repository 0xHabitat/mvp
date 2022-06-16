// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondWritable } from '@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol';

/**
 * @title Basic Git Implementation for an Upgrades and Presets Package Store Diamond
 * @notice This contract allows reading and writing to the upgrades and presets store. It will not
 * act as a borrowed facet, but as a native facet to the Storage Diamond.
 * @dev This contract remains a facet to allow future upgrades of the Git system this diamond 
 * will use. For more context on how this Git system can work under the hood, see Storage.sol.
 */

interface IGit {

  event Commit (
    address owner,
    string name,
    address upgrade
  );

  /**
   * @notice commit an upgrade / preset to the sender's git repo under 'name'
   */
  function commit(
    string calldata name,
    IDiamondWritable.FacetCut[] calldata cuts,
    address target,
    bytes calldata data
  ) external returns (address);

  /**
   * @notice fetch the latest upgrade / preset commit at the owner's repo name
   */
  function latest(
    address owner, 
    string memory name
  ) external view returns (address);
}
