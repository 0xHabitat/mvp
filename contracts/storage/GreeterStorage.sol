// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library GreeterStorage {
    
    struct Layout {
      string greeting;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("greeter.facet.diamond.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
