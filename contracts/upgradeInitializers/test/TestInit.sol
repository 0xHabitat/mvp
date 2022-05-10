// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TestStorage } from "contracts/storage/test/TestStorage.sol";

import "hardhat/console.sol";

contract TestInit {  
    using TestStorage for TestStorage.Layout;

    function init() external {
        TestStorage.Layout storage l = TestStorage.layout();

        l.test = true;
    }
}

// TODO: come up with automated way to provide an 'init' template for end-users