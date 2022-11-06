const fs = require('fs');

async function deployMainDeployer() {

  const ERC20Deployer = await ethers.getContractFactory('ERC20Deployer');
  const erc20Deployer = await ERC20Deployer.deploy();
  await erc20Deployer.deployed();

  const DeciderSignersDeployer = await ethers.getContractFactory('DeciderSignersDeployer');
  const deciderSignersDeployer = await DeciderSignersDeployer.deploy();
  await deciderSignersDeployer.deployed();

  const DeciderVotingPowerDeployer = await ethers.getContractFactory('DeciderVotingPowerDeployer');
  const deciderVotingPowerDeployer = await DeciderVotingPowerDeployer.deploy();
  await deciderVotingPowerDeployer.deployed();

  const VotingPowerManagerDeployer = await ethers.getContractFactory('VotingPowerManagerDeployer');
  const votingPowerManagerDeployer = await VotingPowerManagerDeployer.deploy();
  await votingPowerManagerDeployer.deployed();

  const DAODeployer = await ethers.getContractFactory('DAODeployer');
  const daoDeployer = await DAODeployer.deploy();
  await daoDeployer.deployed();

  const MainDeployer = await ethers.getContractFactory('MainDeployer');
  const mainDeployer = await MainDeployer.deploy(
    erc20Deployer.address,
    deciderSignersDeployer.address,
    deciderVotingPowerDeployer.address,
    votingPowerManagerDeployer.address,
    daoDeployer.address
  );
  await mainDeployer.deployed();
  return mainDeployer;
}

async function deployInitContract() {
  const initContracts = {};

  const InitNames = [
    'DiamondInit',
    'DAOInit',
    'ManagementSystemsInit',
    'TreasuryInit'
  ];

  for (const InitName of InitNames) {
    const InitContract = await ethers.getContractFactory(InitName)
    const initContract = await InitContract.deploy()
    await initContract.deployed()
    initContracts[InitName] = initContract.address;
  }
  return [initContracts, InitNames];
}

async function deployFacets() {
  const facetContracts = {};

  const FacetNames = [
    'DiamondCutFacet',
    'DiamondLoupeFacet',
    'OwnershipFacet',
    'DAOViewerFacet',
    'TreasuryActionsFacet',
    'TreasuryDefaultCallbackHandlerFacet',
    'TreasuryViewerFacet',
    'VotingPowerSpecificDataFacet'
  ];

  let abi = [];
  for (const FacetName of FacetNames) {
    const FacetContract = await ethers.getContractFactory(FacetName)
    const facetContract = await FacetContract.deploy()
    await facetContract.deployed()
    const selectors = getSelectors(facetContract);
    facetContracts[FacetName] = {address: facetContract.address, selectors};
    const facetAbi = facetContract.interface.format(ethers.utils.FormatTypes.json);
    abi = abi.concat(JSON.parse(facetAbi));
  }
  await fs.promises.writeFile('./habitatDiamondABI.json', JSON.stringify(abi, null, 2));
  return [facetContracts, FacetNames];
}

async function deployAddressesProvider() {
  // first deploy all inits and facets
  const [initContracts, initNames] = await deployInitContract();
  const [facetContracts, facetNames] = await deployFacets();

  // deploy addresses provider
  const AddressesProvider = await ethers.getContractFactory('AddressesProvider');
  const addressesProvider = await AddressesProvider.deploy();
  await addressesProvider.deployed();

  // set all deployed inits addresses to addressesProvider
  for (let i = 0; i < initNames.length; i++) {
    await addressesProvider.functions['set' + initNames[i]](initContracts[initNames[i]]);
  }
  // set all deployed facets
  for (let i = 0; i < facetNames.length; i++) {
    await addressesProvider.functions['set' + facetNames[i]](facetContracts[facetNames[i]].address, facetContracts[facetNames[i]].selectors);
  }

  return addressesProvider.address;
}

async function deployMainDeployerAndAddressesProvider() {
  const mainDeployer = await deployMainDeployer();
  const addressesProvider = await deployAddressesProvider();
  const deployed = {
    deployed: true,
    redeploy: false,
    mainDeploer: mainDeployer.address,
    addressesProvider
  }
  await fs.promises.writeFile('./scripts/deployed.json', JSON.stringify(deployed, null, 2));
  return [mainDeployer,addressesProvider];
}

function getSelectors (contract) {
  const signatures = Object.keys(contract.interface.functions)
  const selectors = signatures.reduce((acc, val) => {
    acc.push(contract.interface.getSighash(val))
    return acc
  }, []);
  return selectors
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployMainDeployerAndAddressesProvider()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployMainDeployerAndAddressesProvider = deployMainDeployerAndAddressesProvider;
