// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

import "../../interfaces/treasury/tokens/ERC1155TokenReceiver.sol";
import "../../interfaces/treasury/tokens/ERC721TokenReceiver.sol";
import "../../interfaces/treasury/tokens/ERC777TokensRecipient.sol";

/// @title Default Callback Handler - returns true for known token callbacks
/// @author Richard Meissner - <richard@gnosis.pm>
contract TreasuryDefaultCallbackHandlerFacet is
  ERC1155TokenReceiver,
  ERC777TokensRecipient,
  ERC721TokenReceiver
{
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return 0xf23a6e61;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure override returns (bytes4) {
    return 0xbc197c81;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return 0x150b7a02;
  }

  function tokensReceived(
    address,
    address,
    address,
    uint256,
    bytes calldata,
    bytes calldata
  ) external pure override {
    // We implement this for completeness, doesn't really have any value
  }
}
