// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library TestStorage {

    struct Data {
        string hey;
        uint8 eight;
        uint256[] values;
        mapping(address => bytes) testSelectors;
    }
    
    struct Layout {
        Data data;
        bool test;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("test.facet.diamond.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
