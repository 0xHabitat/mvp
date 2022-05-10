/* global ethers */
/* eslint prefer-const: "off" */
const SourcifyJS = require('sourcify-js');

const fs = require("fs");
const { promises } = fs


async function main () {
// File path where data is to be written
// Here, we assume that the file to be in
// the same location as the .js file
var path = 'MyInitializer.sol';

let storage_contracts = { /// FUCK THIS: USE TYPESCRIPT / TYPECHAIN!!!!
  'TestStorage': {
      data: {
        values: [4, 3, 2, 9],
        eight: 8,
        hey: 'hello'
      },
      test: true,
      initialized: {
        type: Boolean,
        value: true,
      },
      tests: {
        type: Map,
        value: {
          1: {
            testing: {
              type: Boolean,
              value: true
            },
          },
          2: {
            testing: {
              type: Boolean,
              value: false
            },
          }
        }

      }
      // mapping(uint256 => Test) tests,
  },
  'TesterStorage': {
    tester: true,
  },
}

let test_type = 'bool'
let test_name = 'test'
let test_location = ''

let imports = "";
for (let i = 0; i < storage_contracts.length; i++) {
    imports += `import { ${storage_contracts[i].name} } from "contracts/storage/${storage_contracts[i].name}.sol";
`
}

let libraries = "";
for (let i = 0; i < storage_contracts.length; i++) {
  libraries += `using ${storage_contracts[i].name} for ${storage_contracts[i].name}.Layout;
  `
}

let layout = "";
for (let i = 0; i < storage_contracts.length; i++) {
  layout += `${storage_contracts[i].name}.Layout storage l${[i]} = ${storage_contracts[i].name}.layout();
    `
}
   
// Declare a buffer and write the
// data in the buffer
let buffer = new Buffer.from(`

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

${imports}
contract InitTest {  

  ${libraries}
  function init() external {
    
    ${layout}
    // assign storage
    l0.test = true;
    l0.data.hey = "hello";
    l0.data.eight = 8;
    l0.data.values = [8, 2, 3, 5];

    // assign storage
    l1.tester = true;
  }
}

`
);
   
// The fs.open() method takes a "flag"
// as the second argument. If the file
// does not exist, an empty file is
// created. 'a' stands for append mode
// which means that if the program is
// run multiple time data will be
// appended to the output file instead
// of overwriting the existing data.
await promises.writeFile('./contracts/' + path, buffer);
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.main = main
