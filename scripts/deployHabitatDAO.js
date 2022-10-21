/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')
const initParams = require('../initParams.json');
const fs = require('fs');
const IPFS = require('ipfs-http-client')
const deployedContracts = {};

async function deployInitContract() {
  // after addressesProvider is ready write directly to contract
  deployedContracts.initContracts = {};

  const InitNames = [
    'DiamondInit',
    'DAOInit',
    'ManagementSystemsInit',
    'ERC20Init',
    'VotingPowerInitUniV3',
    'TreasuryInit'
  ];

  const initContractInstances = {};

  for (const InitName of InitNames) {
    const InitContract = await ethers.getContractFactory(InitName)
    const initContract = await InitContract.deploy()
    await initContract.deployed()
    deployedContracts.initContracts[InitName] = initContract.address;
    initContractInstances[InitName] = initContract;
  }
  return initContractInstances;
}

const { promises } = fs
async function verify (contracts) {
  const node = await IPFS.create()
  const buildInfo = 'artifacts/build-info'
  const files = await promises.readdir(buildInfo)

  const buildInfoBuffer = await promises.readFile(`${buildInfo}/${files[0]}`)
  const string = await buildInfoBuffer.toString()
  const buildInfoJson = JSON.parse(string)

  for (const contract of contracts) {
    for (const contractsInFile of Object.values(buildInfoJson.output.contracts)) {
      let isRight = Object.keys(contractsInFile).includes(contract.name)
      if (isRight) {
        let buildInfoContract = contractsInFile[contract.name]
        await node.add(Buffer.from(buildInfoContract.metadata))
      }
    }
  }

  return true
}

async function deployFacets() {
  // after addressesProvider is ready write directly to contract
  deployedContracts.facetContracts = {};

  const FacetNames = [
    'DiamondCutFacet',
    'DiamondLoupeFacet',
    'OwnershipFacet',
    'DAOViewerFacet',
    'ERC20Facet',
    'VotingPowerMSViewFacet',
    'VotingPowerFacet',
    'TreasuryDecisionMakingFacet',
    'TreasuryDefaultCallbackHandlerFacet',
    'TreasuryViewerFacet'
  ];

  const facetContractInstances = {};
  let abi = [];
  const contractsToVerify = [];
  for (const FacetName of FacetNames) {
    const FacetContract = await ethers.getContractFactory(FacetName)
    const facetContract = await FacetContract.deploy()
    await facetContract.deployed()
    contractsToVerify.push({
      name: FacetName,
      address: facetContract.address
    })
    deployedContracts.facetContracts[FacetName] = facetContract.address;
    facetContractInstances[FacetName] = facetContract;

    const facetAbi = facetContract.interface.format(ethers.utils.FormatTypes.json);
    abi = abi.concat(JSON.parse(facetAbi));
    // concat
  }
  await fs.promises.writeFile('./habitatDiamondABI.json', JSON.stringify(abi, null, 2));
  verify(contractsToVerify)
  return [facetContractInstances, abi];
}

async function deployDiamond () {
  deployedContracts.external = {};
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  const initContractInstances = await deployInitContract();
  const [facetContractInstances, abi] = await deployFacets();

  // deploy HabitatDiamond
  // after daoFactory is ready refactor
  const HabitatDiamond = await ethers.getContractFactory('HabitatDiamond')
  const habitatDiamond = await HabitatDiamond.deploy(contractOwner.address, facetContractInstances.DiamondCutFacet.address)
  await habitatDiamond.deployed()
  deployedContracts.habitatDiamond = habitatDiamond.address;
  console.log('HabitatDiamond deployed:', habitatDiamond.address)

  // upgrade diamond with facets
  const diamondCut = await ethers.getContractAt('IDiamondCut', habitatDiamond.address)
  let tx
  let receipt
  // start with default cut
  let functionCall = initContractInstances.DiamondInit.interface.encodeFunctionData('init')
  const eipDefaultCut = [
    {
      facetAddress: facetContractInstances.DiamondLoupeFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facetContractInstances.DiamondLoupeFacet)
    },
    {
      facetAddress: facetContractInstances.OwnershipFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facetContractInstances.OwnershipFacet)
    }
  ];

  tx = await diamondCut.diamondCut(eipDefaultCut, deployedContracts.initContracts.DiamondInit, functionCall)
  console.log('Diamond default cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond default upgrade failed: ${tx.hash}`)
  }
  console.log('Completed default diamond cut')

  // DAO cut
  functionCall = initContractInstances.DAOInit.interface.encodeFunctionData('initDAO', [initParams.initDAO.daoName.value, initParams.initDAO.purpose.value, initParams.initDAO.info.value, initParams.initDAO.socials.value, initParams.initDAO.addressesProvider.value]);
  const daoCut = [
    {
      facetAddress: facetContractInstances.DAOViewerFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facetContractInstances.DAOViewerFacet)
    }
  ];

  tx = await diamondCut.diamondCut(daoCut, deployedContracts.initContracts.DAOInit, functionCall)
  console.log('Diamond dao cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond dao upgrade failed: ${tx.hash}`)
  }
  console.log('Completed dao diamond cut')

  // MS cut
  functionCall = initContractInstances.ManagementSystemsInit.interface.encodeFunctionData('initManagementSystems5', [initParams.initManagementSystems5.decisionTypes.value]);
  const msCut = [];

  tx = await diamondCut.diamondCut(msCut, deployedContracts.initContracts.ManagementSystemsInit, functionCall)
  console.log('Diamond ms cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond ms upgrade failed: ${tx.hash}`)
  }
  console.log('Completed ms diamond cut')

  // ERC20 cut
  functionCall = initContractInstances.ERC20Init.interface.encodeFunctionData('initERC20deployInitialDistributor', [initParams.initERC20deployInitialDistributor.tokenName.value, initParams.initERC20deployInitialDistributor.tokenSymbol.value, initParams.initERC20deployInitialDistributor.decimals.value, initParams.initERC20deployInitialDistributor.totalSupply.value]);
  const erc20Cut = [
    {
      facetAddress: facetContractInstances.ERC20Facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facetContractInstances.ERC20Facet)
    }
  ];

  tx = await diamondCut.diamondCut(erc20Cut, deployedContracts.initContracts.ERC20Init, functionCall)
  console.log('Diamond erc20 cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond erc20 upgrade failed: ${tx.hash}`)
  }
  console.log('Completed erc20 diamond cut')

  const initialDistributorAddress = getAddressFromEvent(receipt, "InitialDistributorDeployed(address,address)", 1);
  deployedContracts.external.initialDistributor = initialDistributorAddress;
  console.log('InitialDistributor deployed:', initialDistributorAddress);

  // VotingPower cut
  functionCall = initContractInstances.VotingPowerInitUniV3.interface.encodeFunctionData('initVotingPowerERC20UniV3DeployMainPool', [initParams.initVotingPowerERC20UniV3DeployMainPool._precision.value, initParams.initVotingPowerERC20UniV3DeployMainPool._nfPositionManager.value, initParams.initVotingPowerERC20UniV3DeployMainPool._legalPairTokens.value, initParams.initVotingPowerERC20UniV3DeployMainPool._sqrtPricesX96.value]);
  const votingPowerCut = [
    {
      facetAddress: facetContractInstances.VotingPowerFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facetContractInstances.VotingPowerFacet)
    },
    {
      facetAddress: facetContractInstances.VotingPowerMSViewFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facetContractInstances.VotingPowerMSViewFacet)
    }
  ];

  tx = await diamondCut.diamondCut(votingPowerCut, deployedContracts.initContracts.VotingPowerInitUniV3, functionCall)
  console.log('Diamond voting power cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond voting power upgrade failed: ${tx.hash}`)
  }
  console.log('Completed voting power diamond cut')

  const votingPowerManagerAddress = getAddressFromEvent(receipt, "VotingPowerManagerCreated(address,address)", 1);
  deployedContracts.external.votingPowerManager = votingPowerManagerAddress;
  console.log('VotingPowerManager deployed:', votingPowerManagerAddress);

  // deploy pools
  const legalPairTokens = initParams.initVotingPowerERC20UniV3DeployMainPool._legalPairTokens.value;
  const mainLegalPairToken = legalPairTokens[0];
  let poolsDeployTx;
  if (habitatDiamond.address < mainLegalPairToken) {
    poolsDeployTx = await initContractInstances.VotingPowerInitUniV3.deploy2UniV3Pools(initParams.initVotingPowerERC20UniV3DeployMainPool._nfPositionManager.value, habitatDiamond.address, mainLegalPairToken, [10000, 500], initParams.initVotingPowerERC20UniV3DeployMainPool._sqrtPricesX96.value[0]);
  } else {
    poolsDeployTx = await initContractInstances.VotingPowerInitUniV3.deploy2UniV3Pools(initParams.initVotingPowerERC20UniV3DeployMainPool._nfPositionManager.value, mainLegalPairToken, habitatDiamond.address, [10000, 500], initParams.initVotingPowerERC20UniV3DeployMainPool._sqrtPricesX96.value[1]);
  }
  console.log('Deploy 2 main pools tx: ', poolsDeployTx.hash)
  let poolsDeployReceipt = await poolsDeployTx.wait()
  if (!poolsDeployReceipt.status) {
    throw Error(`Deploy 2 main pools tx failed: ${poolsDeployTx.hash}`)
  }
  console.log('2 main pools are deployed')

  // missing pools deployment for other pair tokens, because we have to think more if we
  // need more legal pair tokens, if we are not planing to take care about prices in
  // those pools it could become an attack vector:
  // the prices in empty pools can be easily moved and it means that attacker
  // can set the price and provide liquidity in a way to get too much voting power
  // for almost nothing
  // - maybe this case can be covered in stake contract logic:
  // - instead of taking current price in a specific pool -> take the current price
  // - of main pool and using uniV3 calculate the market price of the current pool

  // Treasury cut
  functionCall = initContractInstances.TreasuryInit.interface.encodeFunctionData('initTreasuryVotingPower', [initParams.initTreasuryVotingPower.thresholdForInitiator.value, initParams.initTreasuryVotingPower.thresholdForProposal.value, initParams.initTreasuryVotingPower.secondsProposalVotingPeriod.value, initParams.initTreasuryVotingPower.secondsProposalExecutionDelayPeriod.value]);
  const treasuryCut = [
    {
      facetAddress: facetContractInstances.TreasuryDefaultCallbackHandlerFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facetContractInstances.TreasuryDefaultCallbackHandlerFacet)
    },
    {
      facetAddress: facetContractInstances.TreasuryDecisionMakingFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facetContractInstances.TreasuryDecisionMakingFacet)
    },
    {
      facetAddress: facetContractInstances.TreasuryViewerFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facetContractInstances.TreasuryViewerFacet)
    }
  ];

  tx = await diamondCut.diamondCut(treasuryCut, deployedContracts.initContracts.TreasuryInit, functionCall)
  console.log('Diamond treasury cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond treasury upgrade failed: ${tx.hash}`)
  }
  console.log('Completed treasury diamond cut')

  await fs.promises.writeFile('./deployedContracts.json', JSON.stringify(deployedContracts, null, 2));
  return [habitatDiamond.address, abi, deployedContracts.external.initialDistributor, deployedContracts.external.votingPowerManager];
}

function getAddressFromEvent(receipt, eventSignature, topicIndex) {
  const deploymentEvent = receipt.events.find((ev) => {
    if (ev.topics[0] == ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventSignature))) {
      return ev;
    }
  });
  const decodedAddress = ethers.utils.defaultAbiCoder.decode(['address'], deploymentEvent.topics[topicIndex]);
  return decodedAddress[0];
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond
