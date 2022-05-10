// SPDX-License-Identifier: MIT
import { TestStorage } from "contracts/storage/test/TestStorage.sol";
import { TesterStorage } from "contracts/storage/test/TesterStorage.sol";

pragma solidity ^0.8.0;

contract TestFacet1 {
  using TestStorage for TestStorage.Layout;
  using TesterStorage for TesterStorage.Layout;

  function getInitializedValue() external view returns (bool) {
    TestStorage.Layout storage l = TestStorage.layout();
    return l.test;
  }

  function test1Func2() external pure returns (bool) {
    return true;
  }

  // function test1Func3() external pure returns (bool) {
  //   return true;
  // }

  // function test1Func4() external pure returns (bool) {
  //   return true;
  // }

  // function test1Func5() external pure returns (bool) {
  //   return true;
  // }

  // function test1Func6() external pure returns (bool) {
  //   return true;
  // }

  // function test1Func7() external pure returns (bool) {
  //   return true;
  // }

  // function test1Func8() external pure returns (bool) {
  //   return true;
  // }

  // function test1Func9() external pure returns (bool) {
  //   return true;
  // }

  // function test1Func10() external pure returns (bool) {
  //   return true;
  // }

}