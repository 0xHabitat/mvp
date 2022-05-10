// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20BaseInternal } from "@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol";

contract TokenMinter is ERC20BaseInternal {

  /// @notice mints tokens in the context of the calling contract (diamond)
  function execute(uint _proposalId) external {
    if (_proposalId >= 0) {
      _mint(address(this), 500);
    }
  }
}
