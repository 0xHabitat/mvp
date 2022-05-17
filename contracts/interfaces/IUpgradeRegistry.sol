// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondCuttable } from "@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol";

/// @notice register diamondCut params for reuse by a diamond implementing the execute(proposalId) function in Governance
/// @dev registered diamondCuts are callable via the emitted Minimal Proxy Address
interface IUpgradeRegistry {

    event UpgradeRegistered (
    address owner,
    address upgrade, 
    IDiamondCuttable.FacetCut[] facetCuts, 
    address target, 
    bytes data
    );

    /// @notice initiate the diamondCut registration process
    /// @param `IDiamondCuttable.FacetCut[]` memory the facet addresses, actions, function selectors
    /// @param initializer the contract that initializes the diamond's state
    /// @param data the initializer contract's initializer function to be delegatecalled
    function register(IDiamondCuttable.FacetCut[] memory, address initializer, bytes calldata data) external returns (address);

    /// @notice set the diamondCut in the context of the new minimal proxy
    /// @dev when deploying this contract, call this function to set a placeholder diamondCut
    function set(address, IDiamondCuttable.FacetCut[] memory, address, bytes calldata) external;

    /// @notice get the diamondCut in the context of the proposal's proposalContract (minimal proxy) address
    function get() external view returns (IDiamondCuttable.FacetCut[] memory, address, bytes calldata);

    /// @notice delegatecalled from a diamond implementing the execute(proposalId) function
    function execute(uint256) external;
}
