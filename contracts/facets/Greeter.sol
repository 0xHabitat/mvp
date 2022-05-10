
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import { GreeterStorage } from "contracts/storage/GreeterStorage.sol";

contract Greeter {
    using GreeterStorage for GreeterStorage.Layout;

    function greet() public view returns (string memory) {
      GreeterStorage.Layout storage l = GreeterStorage.layout();
      return l.greeting;
    }

    function setGreeting(string memory _greeting) public {
        GreeterStorage.Layout storage l = GreeterStorage.layout();
        l.greeting = _greeting;
    }
}