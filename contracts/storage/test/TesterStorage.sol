// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library TesterStorage {
    
    struct Layout {
        bool tester;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("tester.facet.diamond.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
