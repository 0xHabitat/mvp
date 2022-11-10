const initParams = require('../initParams.json');
const {deployMainDeployerAndAddressesProvider} = require('./deployMainDeployerAndAddressesProvider.js');
const deployed = require('./deployed.json');

async function deployDAO(decisionTypes = initParams.initManagementSystems5.decisionTypes.value) {
  const accounts = await ethers.getSigners();
  const accountDeployerAddress = accounts[0].address;
  // first deploy mainDeployer and addresses provider
  const [mainDeployer,addressesProviderAddress] = !deployed.deployed || deployed.redeploy ? await deployMainDeployerAndAddressesProvider(): [await ethers.getContractAt('MainDeployer', deployed.mainDeploer), deployed.addressesProvider];

  // second deploy hbt, distributor and main pools
  // get return values from the call - returns token and distributor addresses
  const [hbtAddress, initialDistributorAddress] = await mainDeployer.callStatic.deployGovernanceToken(
    initParams.deployGovernanceToken.tokenName.value,
    initParams.deployGovernanceToken.tokenSymbol.value,
    initParams.deployGovernanceToken.totalSupply.value,
    initParams.deployGovernanceToken._sqrtPricesX96.value
  );

  let tx = await mainDeployer.deployGovernanceToken(
    initParams.deployGovernanceToken.tokenName.value,
    initParams.deployGovernanceToken.tokenSymbol.value,
    initParams.deployGovernanceToken.totalSupply.value,
    initParams.deployGovernanceToken._sqrtPricesX96.value
  );
  let receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`ERC20 deployment failed: ${tx.hash}`)
  }

  // third deploy last main pool
  tx = await mainDeployer.deployLastMainPool(
    hbtAddress,
    initParams.deployGovernanceToken._sqrtPricesX96.value
  );
  receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Deployment of last uniV3 pool failed: ${tx.hash}`)
  }

  // fourth deploy three pools for each legal pair token with relative prices
  // TODO make a script to calculate prices
  for (let i = 0; i < initParams.deployThreePools._legalPairTokens.value.length; i++) {
    tx = await mainDeployer.deployThreePools(
      hbtAddress,
      initParams.deployThreePools._legalPairTokens.value[i],
      initParams.deployThreePools._sqrtPricesX96.value[i]
    );
    receipt = await tx.wait();
    if (!receipt.status) {
      throw Error(`Three pools deployment for ${initParams.deployThreePools._legalPairTokens.value[i]} failed: ${tx.hash}`)
    }
  }

  // fifth deploy both deciders and voting power manager
  // get result of function call - returns addresses of contracts
  const [deciderSignersAddress, deciderVotingPowerAddress, stakeContractAddress] = await mainDeployer.callStatic.deployVotingPowerAndSignersDeciders(
    initParams.deployVotingPowerAndSignersDeciders._nfPositionManager.value,
    hbtAddress,
    initParams.deployThreePools._legalPairTokens.value,
    initParams.deployVotingPowerAndSignersDeciders._precision.value,
    "0x0000000000000000000000000000000000000000", // at this point we don't have dao deployed
    accountDeployerAddress, // we use dao setter instead (to set dao address later)
    initParams.deployVotingPowerAndSignersDeciders._gnosisSafe.value
  );

  tx = await mainDeployer.deployVotingPowerAndSignersDeciders(
    initParams.deployVotingPowerAndSignersDeciders._nfPositionManager.value,
    hbtAddress,
    initParams.deployThreePools._legalPairTokens.value,
    initParams.deployVotingPowerAndSignersDeciders._precision.value,
    "0x0000000000000000000000000000000000000000", // at this point we don't have dao deployed
    accountDeployerAddress, // we use dao setter instead (to set dao address later)
    initParams.deployVotingPowerAndSignersDeciders._gnosisSafe.value
  );
  receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Deployment voting power manager and deciders failed: ${tx.hash}`)
  }

  // deploy dao
  const daoMetaData = [initParams.initDAO.daoName.value, initParams.initDAO.purpose.value, initParams.initDAO.info.value, initParams.initDAO.socials.value];
  const decidersRelatedToDecisionTypes = decisionTypes.map(
    (e) => {
      if (e == 2) {
        return deciderVotingPowerAddress;
      }
      if (e == 3) {
        return deciderSignersAddress;
      }
    }
  );

  const abiCoder = ethers.utils.defaultAbiCoder;
  const treasuryVotingPowerSpecificData = abiCoder.encode(
    ["uint64","uint64","uint64","uint64"],
    [
      initParams.initTreasuryVotingPowerSpecificData.thresholdForInitiator.value,
      initParams.initTreasuryVotingPowerSpecificData.thresholdForProposal.value,
      initParams.initTreasuryVotingPowerSpecificData.secondsProposalVotingPeriod.value,
      initParams.initTreasuryVotingPowerSpecificData.secondsProposalExecutionDelayPeriod.value
    ]
  );
  const treasurySignersSpecificData = "0x0000000000000000000000000000000000000000000000000000000000000000";
  // get returned result - dao address
  const daoAddress = await mainDeployer.callStatic.deployDAOMS5T(
    addressesProviderAddress,
    daoMetaData,
    decisionTypes,
    decidersRelatedToDecisionTypes,
    treasuryVotingPowerSpecificData,
    treasurySignersSpecificData
  );

  tx = await mainDeployer.deployDAOMS5T(
    addressesProviderAddress,
    daoMetaData,
    decisionTypes,
    decidersRelatedToDecisionTypes,
    treasuryVotingPowerSpecificData,
    treasurySignersSpecificData
  );
  receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Deployment voting power manager and deciders failed: ${tx.hash}`)
  }

  // set dao into deciders
  const deciderSigners = await ethers.getContractAt('BaseDecider', deciderSignersAddress);
  const deciderVotingPower = await ethers.getContractAt('BaseDecider', deciderVotingPowerAddress);

  tx = await deciderSigners.setDAO(daoAddress);
  await tx.wait();

  tx = await deciderVotingPower.setDAO(daoAddress);
  await tx.wait();

  return [daoAddress,initialDistributorAddress];
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDAO()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDAO = deployDAO
