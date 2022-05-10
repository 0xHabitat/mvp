// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondCuttable } from "@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol";
interface IUpgradeRegistry is IDiamondCuttable {

    event UpgradeRegistered (address, IDiamondCuttable.FacetCut[]);

    function register(IDiamondCuttable.FacetCut[] memory, address, bytes calldata) external returns (address);

    function set(address, FacetCut[] memory, address, bytes calldata) external;

    function get() external view returns (IDiamondCuttable.FacetCut[] memory, address, bytes calldata);

    function execute(uint256) external;
}
