// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ERC20MetadataStorage } from "@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol";
import { ERC20BaseInternal } from "@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol";
import { ERC20BaseStorage } from "@solidstate/contracts/token/ERC20/base/ERC20BaseStorage.sol";

contract ERC20Init is ERC20BaseInternal {
  using ERC20MetadataStorage for ERC20MetadataStorage.Layout;

  function initERC20(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 decimals,
    uint totalSupply
  ) external {
    ERC20MetadataStorage.Layout storage tokenMetadata = ERC20MetadataStorage.layout();
    tokenMetadata.setName(tokenName);
    tokenMetadata.setSymbol(tokenSymbol);
    tokenMetadata.setDecimals(decimals);
    _mint(msg.sender, totalSupply);

  }
}
