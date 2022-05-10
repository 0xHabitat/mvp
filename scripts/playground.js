/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')
const { promises } = require("fs");
const SourcifyJS = require('sourcify-js');
const {
  generateLightFile,
} = require('../tasks/lib/utils.js')

async function main () {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]
  
  let contracts = []

  // deploy interfaces

  // deploy libraries
  

  const MyToken = await ethers.getContractFactory('MyToken')
  const myToken = await MyToken.deploy()
  console.log('MyToken: '+ myToken.address);
  contracts.push({ 
    name: 'MyToken',
    address: myToken.address,
    chainId: 31337
  })

  const HabitatRepository = await ethers.getContractFactory('HabitatRepository')
  const habitatrepo = await HabitatRepository.deploy(contractOwner.address, [
    '0x89e6fEcfc44eDf854cB01a23FA440bDA0d93094F',
    '0xF3e25E7811d645c17441b4525Ed694FF8a419907',
    '0xe62831B6deEeA2a2D1d39788D1961506728e1884',
    '0xc9E39D47C3EDefA20a2575C6C2D6b812927a00eE',
    '0xf97BF98981dD2d0bde488CA79c2f516f61fe2a5b',
    '0xBB6F096064d0FdCD063Ee06922c6a11f04eCE6A0',
    '0x39f15028361E6042a8EC48D61B8aF335DFE0058F',
    '0xb2715578989C8aCe498996F3266Fe0591a7fb487',
    myToken.address
  ])
  console.log('HabitatRepository: '+ habitatrepo.address);
  contracts.push({ 
    name: 'HabitatRepository',
    address: habitatrepo.address,
    chainId: 31337
  })

  const LocalFacet = await ethers.getContractFactory('LocalFacet')
  const localfacet = await LocalFacet.deploy()
  console.log('LocalFacet: '+ localfacet.address);
  contracts.push({ 
    name: 'LocalFacet',
    address: localfacet.address,
    chainId: 31337
  })

  const LocalFacetTest = await ethers.getContractFactory('LocalFacetTest')
  const localfacettest = await LocalFacetTest.deploy()
  console.log('LocalFacetTest: '+ localfacettest.address);
  contracts.push({ 
    name: 'LocalFacetTest',
    address: localfacettest.address,
    chainId: 31337
  })


  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
  const diamondCutFacet = await DiamondCutFacet.deploy()
  console.log('DiamondCutFacet: '+ diamondCutFacet.address);
  contracts.push({ 
    name: 'DiamondCutFacet',
    address: diamondCutFacet.address,
    chainId: 31337
  })
  const sourcify = new SourcifyJS.default('http://localhost:8990', 'http://localhost:5500')
  let json = await generateLightFile()
  const buffer = Buffer.from(JSON.stringify(json))
  const result = await sourcify.verify(31337, contracts, buffer)
  return

  await diamondCutFacet.deployed()
  console.log('DiamondCutFacet deployed:', diamondCutFacet.address)
  contracts.push({ 
    name: 'DiamondCutFacet',
    address: diamondCutFacet.address, 
    chainId: '4'
  })

  // deploy Diamond
  const Diamond = await ethers.getContractFactory('Diamond')
  const diamond = await Diamond.deploy(contractOwner.address, diamondCutFacet.address)
  await diamond.deployed()
  console.log('Diamond deployed:', diamond.address)
  contracts.push({ 
    name: 'Diamond',
    address: diamond.address,
    chainId: '4'
  })

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const DiamondInit = await ethers.getContractFactory('DiamondInit')
  const diamondInit = await DiamondInit.deploy()
  await diamondInit.deployed()
  console.log('DiamondInit deployed:', diamondInit.address)
  contracts.push({ 
    name: 'DiamondInit',
    address: diamondInit.address,
    chainId: '4'
  })

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondLoupeFacet',
    'OwnershipFacet',
    'Test1Facet',
    'Test2Facet'
  ]
  const cut = []
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    contracts.push({ 
      name: FacetName,
      address: facet.address,
      chainId: '4'
    })
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }

  // upgrade diamond with facets
  console.log('')
  console.log('Diamond Cut:', cut)
  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
  let tx
  let receipt
  // call to init function
  let functionCall = diamondInit.interface.encodeFunctionData('init')
  tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
  console.log('Diamond cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed diamond cut')
  
  await promises.writeFile('./' + 'deployments.json', JSON.stringify(contracts, null, 2));
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
