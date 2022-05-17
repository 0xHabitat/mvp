// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
* @notice WIP forwards function data to any diamond
*/

interface IDiamondForwarder {

    /// @notice forwards a delegatecall to any diamond
    /// @param data the function selector with arguments
    function forward(address diamond, bytes memory data) payable external returns (bytes memory);
}
