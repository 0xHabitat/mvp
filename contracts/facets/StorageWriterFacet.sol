// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract StorageWriterFacet {

  function writeToStorageBytes32Blocks(bytes32 position, bytes memory data) external {
    assembly {
      let dataLength := mload(data)
      // Store the bytes content by blocks of 32 bytes
      for {let i:= 0} lt(mul(i, 0x20), dataLength) {i := add(i, 0x01)} {
        sstore(add(position, i), mload(add(data, mul(add(i, 1), 0x20))))
      }
    }
  }

  function readStorageSlot(bytes32 position) external view returns(bytes32 v) {
    assembly {
      v := sload(position)
    }
  }

  function readStorageBytes32Blocks(bytes32 position, uint length) external view returns(bytes memory storedStruct) {
    storedStruct = new bytes(length);
    assembly {
      for {let i:=0} lt(mul(i, 0x20), length) {i := add(i, 0x01)} {
        let storedBlock32bytes := sload(add(position, i))
        mstore(add(storedStruct, add(0x20, mul(i, 0x20))), storedBlock32bytes)
      }
    }
  }


}
