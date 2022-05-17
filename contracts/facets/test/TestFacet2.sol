// SPDX-License-Identifier: MIT
import { TestStorage } from "contracts/storage/test/TestStorage.sol";

pragma solidity ^0.8.0;

contract TestFacet2 {
  using TestStorage for TestStorage.Layout;

  function test2Func1() external pure returns (bool) {
    return true;
  }

  function test2Func2() external pure returns (bool) {
    return true;
  }

  function test2Func3() external pure returns (bool) {
    return true;
  }

  function test2Func4() external pure returns (bool) {
    return true;
  }

  function test12Func5() external pure returns (bool) {
    return true;
  }

}