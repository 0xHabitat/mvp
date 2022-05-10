// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SafeOwnable, OwnableStorage } from "@solidstate/contracts/access/SafeOwnable.sol";

contract OwnershipFacet is SafeOwnable {
    receive() external payable {}
}