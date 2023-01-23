const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const { deployDAO } = require("../scripts/deployDAO.js");
const { getContractsForUniV3, getWETH } = require('./helpers/getContractsForUniV3.js');
const habitatABI = require('../habitatDiamondABI.json');

describe('HabitatDiamond', function () {
  async function deployDAOFixture() {
    const accounts = await ethers.getSigners();
    signer = accounts[0];
    const [daoAddress, initialDistributorAddress] = await deployDAO();
    const habitatDiamond = new ethers.Contract(daoAddress, habitatABI, signer);
    const initialDistributor = await ethers.getContractAt('InitialDistributorAbleToStake', initialDistributorAddress, signer);
    const deciderVotingPowerAddress = await habitatDiamond.callStatic.getDecider("treasury");
    const deciderVotingPower = await ethers.getContractAt('DeciderVotingPower', deciderVotingPowerAddress);
    const stakeContractAddress = await deciderVotingPower.getVotingPowerManager();
    const stakeERC20Contract = await ethers.getContractAt('StakeContractERC20UniV3', stakeContractAddress, signer);
    const addresses = accounts.map((val) => {
      return val.address;
    });
    return {habitatDiamond, initialDistributor, deciderVotingPower, stakeERC20Contract, accounts, addresses};
  }

  async function deployDAOAndDistributeFixture() {
    const {habitatDiamond, initialDistributor, deciderVotingPower, stakeERC20Contract, accounts, addresses} = await helpers.loadFixture(deployDAOFixture);
    // paste distribute logic
    const hbtAddress = await stakeERC20Contract.governanceToken();
    const hbtToken = await ethers.getContractAt('HBT', hbtAddress);
    const hbtTotalSupply = await hbtToken.totalSupply();
    let tx = await initialDistributor.setStakeERC20Contract(stakeERC20Contract.address);
    await tx.wait();
    const numberOfAddresses = ethers.BigNumber.from(addresses.length);
    const halfOfTokens = hbtTotalSupply.div(2);
    const shareOfHalfOfTokens = halfOfTokens.div(numberOfAddresses);
    // distribute tokens directly
    tx = await initialDistributor.distributeMultiple(addresses, Array(addresses.length).fill(shareOfHalfOfTokens));
    await tx.wait();
    // stake tokens in favor of addresses
    tx = await initialDistributor.stakeTokensInFavorOfMultipleAddresses(addresses, Array(addresses.length).fill(shareOfHalfOfTokens), halfOfTokens);
    await tx.wait();
    // let's fund DAO treasury with some ETH and WETH
    const sponsor = accounts[0];
    const weth = getWETH(sponsor);
    tx = await weth.deposit({value: ethers.constants.WeiPerEther.mul(10)});
    await tx.wait();
    tx = await weth.transfer(habitatDiamond.address, ethers.constants.WeiPerEther.mul(10));
    await tx.wait();
    const ethTranfer = {
      to: habitatDiamond.address,
      value: ethers.utils.parseEther('10', 'ether')
    }
    tx = await sponsor.sendTransaction(ethTranfer);
    await tx.wait();

    return {habitatDiamond, hbtToken, stakeERC20Contract, deciderVotingPower, accounts, addresses, weth};
  }

  async function deployDAOAndDistributeAndVPEnoughForGovernanceFixture() {
    const {habitatDiamond, hbtToken, stakeERC20Contract, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeFixture);
    // let's give addresses[0] enough voting power to create governance proposals
    // by delegating from addresses[9]
    const tx = await deciderVotingPower.connect(accounts[9]).delegateVotingPower(addresses[0]);
    await tx.wait();

    return {habitatDiamond, deciderVotingPower, accounts, addresses};
  }

  it('VotingPower/ERC20: should distribute tokens', async function () {
    const {habitatDiamond, initialDistributor, deciderVotingPower, stakeERC20Contract, addresses} = await helpers.loadFixture(deployDAOFixture);
    const hbtAddress = await stakeERC20Contract.governanceToken();
    const hbtToken = await ethers.getContractAt('HBT', hbtAddress);
    const hbtTotalSupply = await hbtToken.totalSupply();
    let initialDistributorBalance = await hbtToken.balanceOf(initialDistributor.address);
    expect(initialDistributorBalance).to.eq(hbtTotalSupply);

    let stakeContractBalance = await hbtToken.balanceOf(stakeERC20Contract.address);
    assert(stakeContractBalance.isZero(), 'stake contract at this point must be empty');

    let tx = await initialDistributor.setStakeERC20Contract(stakeERC20Contract.address);
    await tx.wait();
    // distribute tokens directly
    const numberOfAddresses = ethers.BigNumber.from(addresses.length);
    const halfOfTokens = hbtTotalSupply.div(2);
    const shareOfHalfOfTokens = halfOfTokens.div(numberOfAddresses);
    tx = await initialDistributor.distributeMultiple(addresses, Array(addresses.length).fill(shareOfHalfOfTokens));
    await tx.wait();
    for (let i = 0; i < addresses.length; i++) {
      const balance = await hbtToken.balanceOf(addresses[i]);
      expect(balance).to.eq(shareOfHalfOfTokens);
    }
    initialDistributorBalance = await hbtToken.balanceOf(initialDistributor.address);
    expect(initialDistributorBalance).to.eq(hbtTotalSupply.sub(halfOfTokens));
    // stake tokens in favor of addresses
    tx = await initialDistributor.stakeTokensInFavorOfMultipleAddresses(addresses, Array(addresses.length).fill(shareOfHalfOfTokens), halfOfTokens);
    receipt = await tx.wait()

    initialDistributorBalance = await hbtToken.balanceOf(initialDistributor.address);
    assert(initialDistributorBalance.isZero(), 'initial distributor at this point must be empty');

    stakeContractBalance = await hbtToken.balanceOf(stakeERC20Contract.address);
    expect(stakeContractBalance).to.eq(halfOfTokens);

    for (let i = 0; i < addresses.length; i++) {
      // first check stake contract effects
      const stakedBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(addresses[i]);
      expect(stakedBalance).to.eq(shareOfHalfOfTokens);
      // second check dao contract effects
      const votingPower = await deciderVotingPower.getVoterVotingPower(addresses[i]);
      expect(votingPower).to.eq(stakedBalance);
    }
  });

  it('VotingPower/ERC20Staking: should be able to stake/unstake governance token', async function () {
    const {habitatDiamond, hbtToken, stakeERC20Contract, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeFixture);
    const amountToStakeUnstake = await hbtToken.balanceOf(addresses[0]);
    // when stake/unstake totalAmountOfVotingPower increase/decrease
    const totalAmountOfVotingPowerBeforeStaking = await deciderVotingPower.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerBeforeStaking.gt(0)).to.be.true;
    // should stake
    for (let i = 1; i < addresses.length; i++) {
      let tokenBalance = await hbtToken.balanceOf(addresses[i]);
      expect(tokenBalance).eq(amountToStakeUnstake);
      const stakeERC20ContractNewSigner = stakeERC20Contract.connect(accounts[i]);
      const hbtTokenNewSigner = hbtToken.connect(accounts[i]);
      // first give allowance to stake contract
      let tx = await hbtTokenNewSigner.approve(stakeERC20Contract.address, tokenBalance);
      await tx.wait();
      const allowedAmount = await hbtToken.allowance(addresses[i], stakeERC20Contract.address);
      expect(allowedAmount).to.eq(tokenBalance);
      // second stake
      tx = await stakeERC20ContractNewSigner.stakeGovToken(amountToStakeUnstake);
      await tx.wait();
      // confirm effects
      tokenBalance = await hbtToken.balanceOf(addresses[i]);
      expect(tokenBalance.isZero()).to.be.true;
      const stakedERC20GovTokenBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(addresses[i]);
      expect(stakedERC20GovTokenBalance.gte(amountToStakeUnstake)).to.be.true;
      const currentTotalAmountOfVotingPower = await deciderVotingPower.getTotalAmountOfVotingPower();
      expect(currentTotalAmountOfVotingPower).to.eq(totalAmountOfVotingPowerBeforeStaking.add(amountToStakeUnstake.mul(i)));
      const votingPower = await deciderVotingPower.getVoterVotingPower(addresses[i]);
      expect(votingPower.gte(amountToStakeUnstake)).to.be.true;
    }
    // should unstake
    const totalAmountOfVotingPowerAfterStaking = await deciderVotingPower.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerAfterStaking.gt(0)).to.be.true;
    for (let i = 1; i < addresses.length; i++) {
      const votingPower = await deciderVotingPower.getVoterVotingPower(addresses[i]);
      const stakedERC20GovTokenBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(addresses[i]);
      const tokenBalance = await hbtToken.balanceOf(addresses[i]);

      const stakeERC20ContractNewSigner = stakeERC20Contract.connect(accounts[i]);
      // first check if able to unstake
      const unstakeTimestamp = await deciderVotingPower.getTimestampToUnstake(addresses[i]);
      // no voting happened (rare case) must be 0
      expect(unstakeTimestamp.isZero()).to.be.true;
      // majority of cases we take current block timestamp
      const currentBlock = await ethers.provider.getBlock('latest');
      // if not true staker must wait
      expect(unstakeTimestamp.lte(currentBlock.timestamp)).to.be.true;

      // second unstake
      tx = await stakeERC20ContractNewSigner.unstakeGovToken(amountToStakeUnstake);
      await tx.wait();

      // confirm effects
      const votingPowerAfterUnstake = await deciderVotingPower.getVoterVotingPower(addresses[i]);
      expect(votingPowerAfterUnstake).eq(votingPower.sub(amountToStakeUnstake));
      const stakedERC20GovTokenBalanceAfterUnstake = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(addresses[i]);
      expect(stakedERC20GovTokenBalanceAfterUnstake).eq(stakedERC20GovTokenBalance.sub(amountToStakeUnstake));
      const tokenBalanceAfterUnstake = await hbtToken.balanceOf(addresses[i]);
      expect(tokenBalanceAfterUnstake).eq(tokenBalance.add(amountToStakeUnstake));
    }
  });

  it('VotingPower/UNIV3Staking: should be able to stake/unstake NFT position', async function () {
    const {habitatDiamond, hbtToken, stakeERC20Contract, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeFixture);
    const newSigner = accounts[2];
    const hbtTokenNewSigner = hbtToken.connect(newSigner);
    const stakeERC20ContractNewSigner = stakeERC20Contract.connect(newSigner);
    const fee = 3000;
    const tickSpacing = 60;
    const {weth, nfPositionManager, pool} = getContractsForUniV3(hbtToken.address, fee, newSigner);
    // first provide liquidity
    // prepare mintParams
    const block = await ethers.provider.getBlock('latest');
    const isHBTToken0 = ethers.BigNumber.from(hbtToken.address).lt(ethers.BigNumber.from(weth.address));
    const slot0 = await pool.slot0();

    const tickLower = slot0.tick - (slot0.tick % tickSpacing);
    const tickUpper = tickLower + tickSpacing;
    const mintParams = {
      token0: isHBTToken0 ? hbtToken.address : weth.address,
      token1: isHBTToken0 ? weth.address : hbtToken.address,
      fee: 3000,
      tickLower,
      tickUpper,
      amount0Desired: isHBTToken0 ? ethers.constants.WeiPerEther.mul(10000) : ethers.constants.WeiPerEther.mul(10),
      amount1Desired: isHBTToken0 ? ethers.constants.WeiPerEther.mul(10) : ethers.constants.WeiPerEther.mul(10000),
      amount0Min: 0,
      amount1Min: 0,
      recipient: newSigner.address,
      deadline: block.timestamp + 100000
    };

    // convert ETH to WETH and give approvals for nfPositionManager
    let tx = await weth.deposit({value: ethers.constants.WeiPerEther.mul(10)});
    await tx.wait();
    const wethBalance = await weth.balanceOf(newSigner.address);
    //expect(wethBalance).to.eq(ethers.constants.WeiPerEther.mul(10));
    // above line is commented, because loadFixture doesn't do exactly what it declares to do (snapshot is not about the whole state)
    // you can uncomment, but have to rerun node everytime you run tests
    tx = await weth.approve(nfPositionManager.address, ethers.constants.WeiPerEther.mul(10));
    await tx.wait();
    const wethAllowedAmount = await weth.allowance(newSigner.address, nfPositionManager.address);
    //expect(wethAllowedAmount).to.eq(wethBalance);

    tx = await hbtTokenNewSigner.approve(nfPositionManager.address, ethers.constants.WeiPerEther.mul(10000));
    await tx.wait();
    const habitatAllowedAmount = await hbtTokenNewSigner.allowance(newSigner.address, nfPositionManager.address);
    expect(habitatAllowedAmount).to.eq(ethers.constants.WeiPerEther.mul(10000));

    // provide liquidity = mint NFTposition
    const tokenId = (await nfPositionManager.callStatic.mint(mintParams))[0];
    tx = await nfPositionManager.mint(mintParams);
    await tx.wait();
    const ownerOfNFTposition = await nfPositionManager.ownerOf(tokenId);
    expect(ownerOfNFTposition).to.eq(newSigner.address);

    // second stake NFTpositions
    // first approve = make stake contract operator
    tx = await nfPositionManager.approve(stakeERC20Contract.address, tokenId);
    await tx.wait();
    const position = await nfPositionManager.positions(tokenId);
    expect(position.operator).to.eq(stakeERC20Contract.address);
    expect(position.token0).to.eq(isHBTToken0 ? hbtToken.address : weth.address);
    expect(position.token1).to.eq(isHBTToken0 ? weth.address : hbtToken.address);

    // stake NFTposition
    const votingPowerBeforeStake = await deciderVotingPower.getVoterVotingPower(newSigner.address);
    const totalAmountOfVotingPowerBeforeStaking = await deciderVotingPower.getTotalAmountOfVotingPower();

    tx = await stakeERC20ContractNewSigner.stakeUniV3NFTPosition(tokenId);
    await tx.wait();
    // confirm effects
    let newOwnerOfNFTposition = await nfPositionManager.ownerOf(tokenId);
    expect(newOwnerOfNFTposition).to.eq(stakeERC20ContractNewSigner.address);
    let isStakedByHolder = await stakeERC20Contract.nftPositionIsStakedByHolder(newSigner.address, tokenId);
    expect(isStakedByHolder).to.be.true;
    // maybe write pure function that returns the amount without staking?
    const amountOfVotingPowerForNFT = await stakeERC20Contract.getAmountOfVotingPowerForNFTPosition(tokenId);
    const votingPowerAfterStake = await deciderVotingPower.getVoterVotingPower(newSigner.address);
    expect(votingPowerAfterStake).to.eq(votingPowerBeforeStake.add(amountOfVotingPowerForNFT));
    const totalAmountOfVotingPowerAfterStaking = await deciderVotingPower.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerAfterStaking).to.eq(totalAmountOfVotingPowerBeforeStaking.add(amountOfVotingPowerForNFT));

    // unstake nft position
    const unstakeTimestamp = await deciderVotingPower.getTimestampToUnstake(newSigner.address);
    // no voting happened (rare case) must be 0
    expect(unstakeTimestamp.isZero()).to.be.true;
    tx = await stakeERC20ContractNewSigner.unstakeUniV3NFTPosition(tokenId);
    await tx.wait();
    // confirm effects
    const totalAmountOfVotingPowerAfterUnstake = await deciderVotingPower.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerAfterUnstake).to.eq(totalAmountOfVotingPowerBeforeStaking);
    const votingPowerAfterUnstake = await deciderVotingPower.getVoterVotingPower(newSigner.address);
    expect(votingPowerAfterUnstake).to.eq(votingPowerBeforeStake);
    isStakedByHolder = await stakeERC20Contract.nftPositionIsStakedByHolder(newSigner.address, tokenId);
    expect(isStakedByHolder).to.be.false;
    newOwnerOfNFTposition = await nfPositionManager.ownerOf(tokenId);
    expect(newOwnerOfNFTposition).to.eq(newSigner.address);
  });

  it('VotingPower/Delegation: should be able to delegate/undelegate', async function () {
    const {habitatDiamond, hbtToken, stakeERC20Contract, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeFixture);
    const delegator = accounts[1];
    const deciderVotingPowerDelegator = deciderVotingPower.connect(delegator);
    const delegatee = accounts[2];
    const delegatorVotingPowerBefore = await deciderVotingPower.getVoterVotingPower(delegator.address);
    expect(delegatorVotingPowerBefore.gt(0)).to.be.true;
    const delegateeVotingPowerBefore = await deciderVotingPower.getVoterVotingPower(delegatee.address);
    // delegate
    let tx = await deciderVotingPowerDelegator.delegateVotingPower(delegatee.address);
    await tx.wait();
    const delegatorVotingPowerAfter = await deciderVotingPower.getVoterVotingPower(delegator.address);
    expect(delegatorVotingPowerAfter.isZero()).to.be.true;
    const delegateeVotingPowerAfter = await deciderVotingPower.getVoterVotingPower(delegatee.address);
    expect(delegateeVotingPowerAfter).to.eq(delegateeVotingPowerBefore.add(delegatorVotingPowerBefore));
    const delegateeCorrect = await deciderVotingPower.getDelegatee(delegator.address);
    expect(delegateeCorrect).to.eq(delegatee.address);
    const delegatedVotingPower = await deciderVotingPower.getAmountOfDelegatedVotingPower(delegator.address);
    expect(delegatedVotingPower).to.eq(delegatorVotingPowerBefore);
    // undelegate
    tx = await deciderVotingPowerDelegator.undelegateVotingPower();
    await tx.wait();
    const delegatorVotingPowerUndelegated = await deciderVotingPower.getVoterVotingPower(delegator.address);
    expect(delegatorVotingPowerUndelegated).to.eq(delegatorVotingPowerBefore);
    const delegateeVotingPowerUndelegated = await deciderVotingPower.getVoterVotingPower(delegatee.address);
    expect(delegateeVotingPowerUndelegated).to.eq(delegateeVotingPowerBefore);
  });

  it('VotingPower/Treasury module: should be able to create treasury proposal', async function () {
    const {habitatDiamond, hbtToken, stakeERC20Contract, deciderVotingPower, accounts, addresses, weth} = await helpers.loadFixture(deployDAOAndDistributeFixture);
    const ten = ethers.constants.WeiPerEther.mul(10);
    // first lets make voting power 0 and try to create treasury proposal
    const unstaker = accounts[1];
    const beneficiar = addresses[3];
    const thresholdForInitiatorNumerator = await habitatDiamond.callStatic.thresholdForInitiatorNumerator('treasury');
    expect(await deciderVotingPower.callStatic.isEnoughVotingPower(unstaker.address, thresholdForInitiatorNumerator))
      .to.be.true;
    const stakedBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(unstaker.address);
    const stakeERC20ContractUnstaker = stakeERC20Contract.connect(unstaker);
    const habitatDiamondUnstaker = habitatDiamond.connect(unstaker);
    let tx = await stakeERC20ContractUnstaker.unstakeGovToken(stakedBalance);
    await tx.wait();
    const unstakerVotingPower = await deciderVotingPower.getVoterVotingPower(unstaker.address);
    expect(unstakerVotingPower.isZero()).to.be.true;
    expect(await deciderVotingPower.callStatic.isEnoughVotingPower(unstaker.address, thresholdForInitiatorNumerator))
      .to.be.false;
    await expect(habitatDiamondUnstaker.createTreasuryProposal(unstaker.address, ten, '0x'))
      .to.be.revertedWith("Not enough voting power to create proposal.");

    // second lets try to create a proposal that is calling diamond itself
    await expect(habitatDiamond.createTreasuryProposal(habitatDiamond.address, '0x0', '0x11223344'))
      .to.be.revertedWith("Not a treasury proposal.");

    // third lets try create a proposal to transfer HBT tokens from treasury
    let callData = hbtToken.interface.encodeFunctionData('transfer', [beneficiar, ten.mul(1000)]);
    const proposalId = await habitatDiamond.callStatic.createTreasuryProposal(hbtToken.address, '0x0', callData);
    expect(proposalId).to.eq(ethers.constants.One);

    // lets create proposal to transfer ETH
    const treasuryExecutionDelay = await habitatDiamond.callStatic.getSecondsProposalExecutionDelayPeriodVP('treasury');
    const treasuryVotingPeriod = await habitatDiamond.callStatic.getSecondsProposalVotingPeriod('treasury');
    const proposalIDToTransferETH = await habitatDiamond.callStatic.createTreasuryProposal(beneficiar, ten, '0x');
    let currentBlock = await ethers.provider.getBlock('latest');
    await expect(habitatDiamond.createTreasuryProposal(beneficiar, ten, '0x'))
      .to.emit(habitatDiamond, "ProposalCreated")
      .withArgs('treasury', proposalIDToTransferETH)

    let proposal = await habitatDiamond.callStatic.getTreasuryProposal(proposalIDToTransferETH);
    expect(proposal.proposalAccepted).to.be.false;
    expect(proposal.destinationAddress).to.eq(beneficiar);
    expect(proposal.value).to.eq(ten);
    expect(proposal.callData).to.eq('0x');
    expect(proposal.proposalExecuted).to.be.false;
    expect(proposal.executionTimestamp).to.be.closeTo(treasuryVotingPeriod.add(currentBlock.timestamp).add(treasuryExecutionDelay), 3);

    // lets create proposal to transfer WETH
    callData = weth.interface.encodeFunctionData('transfer', [beneficiar, ten]);
    const proposalIDToTransferWETH = (await habitatDiamond.callStatic.getTreasuryProposalsCount()).add(1);
    currentBlock = await ethers.provider.getBlock('latest');
    await expect(habitatDiamond.createTreasuryProposal(weth.address, '0x0', callData))
      .to.emit(habitatDiamond, "ProposalCreated")
      .withArgs('treasury', proposalIDToTransferWETH)

    proposal = await habitatDiamond.callStatic.getTreasuryProposal(proposalIDToTransferWETH);
    expect(proposal.proposalAccepted).to.be.false;
    expect(proposal.destinationAddress).to.eq(weth.address);
    expect(proposal.value.isZero()).to.be.true;
    expect(proposal.callData).to.eq(callData);
    expect(proposal.proposalExecuted).to.be.false;
    expect(proposal.executionTimestamp).to.be.closeTo(treasuryVotingPeriod.add(currentBlock.timestamp).add(treasuryExecutionDelay), 3);
  });

  it('VotingPower/Treasury module: should be able to decide on treasury proposal', async function () {
    const {habitatDiamond, hbtToken, stakeERC20Contract, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeFixture);
    const ten = ethers.constants.WeiPerEther.mul(10);
    const beneficiar = addresses[3];
    // first lets create treasury proposal
    const proposalID = (await habitatDiamond.callStatic.getTreasuryProposalsCount()).add(1);
    let tx = await habitatDiamond.createTreasuryProposal(beneficiar, ten, '0x');
    await tx.wait();
    // make sure that treasury decisionType is votingPowerERC20
    const decisionType = await habitatDiamond.callStatic.getTreasuryDecisionType();
    expect(decisionType).to.eq(2);
    // lets find our proposalId in active voting
    let activeVotingProposalIds = await habitatDiamond.callStatic.getTreasuryActiveProposalsIds();
    expect(activeVotingProposalIds.some((id) => id.eq(proposalID))).to.be.true;
    // the initiator already voted
    expect(await deciderVotingPower.callStatic.isHolderVotedForProposal('treasury', proposalID, addresses[0]))
      .to.be.true;
    const initiatorVotingPower = await deciderVotingPower.getVoterVotingPower(accounts[0].address);
    let votesYes = await deciderVotingPower.callStatic.getProposalVotingVotesYes('treasury', proposalID);
    expect(votesYes).to.eq(initiatorVotingPower);

    // make sure voting started
    expect(await deciderVotingPower.callStatic.isVotingForProposalStarted('treasury', proposalID))
      .to.be.true;
    const votingDeadline = await deciderVotingPower.callStatic.getProposalVotingDeadlineTimestamp('treasury', proposalID);
    const currentBlock = await ethers.provider.getBlock('latest');
    expect(votingDeadline.gt(currentBlock.timestamp)).to.be.true;

    // lets decide
    // lets decide on non-exist proposal
    await expect(habitatDiamond.decideOnTreasuryProposal('0x12', true))
      .to.be.revertedWith("No voting rn.");
    // lets decide second time
    await expect(habitatDiamond.decideOnTreasuryProposal(proposalID, true))
      .to.be.revertedWith("Already voted.");
    // lets stake more govTokens, get more votingPower and decide again
    const balance = await hbtToken.balanceOf(addresses[0]);
    tx = await hbtToken.approve(stakeERC20Contract.address, balance);
    await tx.wait();
    tx = await stakeERC20Contract.stakeGovToken(balance);
    await tx.wait();
    tx = await habitatDiamond.decideOnTreasuryProposal(proposalID, true);
    await tx.wait();
    votesYes = await deciderVotingPower.callStatic.getProposalVotingVotesYes('treasury', proposalID);
    expect(votesYes).to.eq(initiatorVotingPower.add(balance));

    await expect(habitatDiamond.connect(accounts[1]).decideOnTreasuryProposal(proposalID, true))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[1], 'treasury', proposalID, true);

    const votingPowerAccount1 = await deciderVotingPower.getVoterVotingPower(accounts[1].address);
    expect(await deciderVotingPower.callStatic.getProposalVotingVotesYes('treasury', proposalID))
      .to.eq(votesYes.add(votingPowerAccount1));


    await expect(habitatDiamond.connect(accounts[2]).decideOnTreasuryProposal(proposalID, false))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[2], 'treasury', proposalID, false);

    const votingPowerAccount2 = await deciderVotingPower.getVoterVotingPower(accounts[2].address);
    const votesNo = await deciderVotingPower.callStatic.getProposalVotingVotesNo('treasury', proposalID);
    expect(votesNo).to.eq(votingPowerAccount2);

    const thresholdForProposalNumerator = await habitatDiamond.callStatic.thresholdForProposalNumerator('treasury');
    const thresholdForProposalReachedVotesYes = await deciderVotingPower.callStatic.isProposalThresholdReached(votesYes, thresholdForProposalNumerator);
    expect(thresholdForProposalReachedVotesYes).to.be.true;

    const absoluteThresholdForProposal = await deciderVotingPower.callStatic.getAbsoluteThresholdByNumerator(thresholdForProposalNumerator);
    votesYes = await deciderVotingPower.callStatic.getProposalVotingVotesYes('treasury', proposalID);
    expect(absoluteThresholdForProposal.lte(votesYes)).to.be.true;

    // accept proposal
    // lets try to accept not waiting voting period
    await expect(habitatDiamond.acceptOrRejectTreasuryProposal(proposalID))
      .to.be.revertedWith("Voting period is not ended yet.");

    // lets move to timestamp when voting period is ended
    await helpers.time.increaseTo(votingDeadline);
    await expect(habitatDiamond.acceptOrRejectTreasuryProposal(proposalID))
      .to.emit(habitatDiamond, "ProposalAccepted")
      .withArgs('treasury', proposalID, beneficiar, ten, '0x');
    // confirm proposalId is removed from active
    activeVotingProposalIds = await habitatDiamond.callStatic.getTreasuryActiveProposalsIds();
    expect(activeVotingProposalIds.some((id) => id.eq(proposalID))).to.be.false;
    // confirm proposal voting was removed
    votesYes = await deciderVotingPower.callStatic.getProposalVotingVotesYes('treasury', proposalID);
    expect(votesYes.isZero()).to.be.true;
    // TODO also missed acceptedProposals view func

    // execute proposal
    // lets try to execute not waiting delay period
    await expect(habitatDiamond.executeTreasuryProposal(proposalID))
      .to.be.revertedWith("Wait until proposal delay time is expired.");

    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.callStatic.getTreasuryProposal(proposalID);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    const beneficiarETHBalanceBefore = await ethers.provider.getBalance(beneficiar);
    const habitatDAOETHBalanceBefore = await ethers.provider.getBalance(habitatDiamond.address);
    // let execute
    await expect(habitatDiamond.executeTreasuryProposal(proposalID))
      .to.emit(habitatDiamond, "ProposalExecutedSuccessfully")
      .withArgs('treasury', proposalID);

    // confirm receiving eth
    const beneficiarETHBalanceAfter = await ethers.provider.getBalance(beneficiar);
    expect(beneficiarETHBalanceBefore.add(ten)).to.eq(beneficiarETHBalanceAfter);
    const habitatDAOETHBalanceAfter = await ethers.provider.getBalance(habitatDiamond.address);
    expect(habitatDAOETHBalanceBefore.sub(ten)).to.eq(habitatDAOETHBalanceAfter);
    // TODO create proposal to transfer WETH and vote no to reject
  });

  it('Governance module(VP): test changeThresholdForInitiator governance method', async function () {
    const {habitatDiamond, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeFixture);
    const thresholdForInitiatorGovernanceNumerator = await habitatDiamond.thresholdForInitiatorNumerator("governance");
    let allowedToInitiateGovernanceProposal = await deciderVotingPower.isEnoughVotingPower(addresses[0], thresholdForInitiatorGovernanceNumerator);
    expect(allowedToInitiateGovernanceProposal).to.be.false;
    // let's give addresses[0] enough voting power to create governance proposals
    // by delegating from addresses[9]
    const delegateeAmountOfVotingPowerBefore = await deciderVotingPower.getVoterVotingPower(addresses[0]);
    await deciderVotingPower.connect(accounts[9]).delegateVotingPower(addresses[0]);
    const delegateeAmountOfVotingPowerAfter = await deciderVotingPower.getVoterVotingPower(addresses[0]);
    expect(delegateeAmountOfVotingPowerBefore.mul(2)).to.eq(delegateeAmountOfVotingPowerAfter);
    allowedToInitiateGovernanceProposal = await deciderVotingPower.isEnoughVotingPower(addresses[0], thresholdForInitiatorGovernanceNumerator);
    expect(allowedToInitiateGovernanceProposal).to.be.true;

    // testing our Governance module functionality
    // we try to change value of specific data of decision type Voting Power
    // value is threshold for initiator (description: "Value is the percentage (0.1% - 0.001 * 10000). The percentage helps to calculate the thresholdForInitiator by multiplying with maxAmountOfVotingPower (or with totalAmountOfVotingPower if it is more). Absolute value is used as a restriction for creating proposals (comparison: if initiator amount of votingPower is less than a value - is not able to create.")
    // testing case:
    //   Treasury module - which currently has Voting Power as decision type
    //   which after proposal will be executed will have immediate effect on Treasury
    //   decision process (if we increase/decrease value less/more voting power holders
    //   are able to create treasury proposals)
    // notice: if we try to change this value for Module manager
    //   which currently has Signers as decision type after proposal will be executed
    //   will not have immediate effect on Module manager decision process
    //   and only would have if it's decision type
    //   would be changed to Voting Power by Module Manager functionality

    // this value (percentage) we try to change
    const treasuryThresholdForInitiatorNumerator = await habitatDiamond.thresholdForInitiatorNumerator("treasury");
    expect(treasuryThresholdForInitiatorNumerator.eq(50)).to.be.true;

    // let's prove that holder 4 is able to create treasury proposal with threshold equals 0.5%
    const tProposalId1 = await habitatDiamond.connect(accounts[4]).callStatic.createTreasuryProposal(addresses[4],0,'0x')
    await expect(habitatDiamond.connect(accounts[4]).createTreasuryProposal(addresses[4],0,'0x'))
      .to.emit(habitatDiamond, "ProposalCreated")
      .withArgs('treasury', tProposalId1);


    /*
    // how are we getting decider instance?
    async function getDeciderContractInstance(moduleName) {
      const deciderType = await habitatDiamond.getModuleDecisionType(moduleName);
      const deciderAddress = await habitatDiamond.getDecider(moduleName);
      if (deciderType !== 2 || deciderType !== 3) return "decider is not implemented";
      const deciderABI = deciderType == 2 ? 'DeciderVotingPower' : 'DeciderSigners';
      const deciderInstance = await ethers.getContractAt(deciderABI, deciderAddress);
      return deciderInstance;
    }
    */

    // let's get absolute value of voting power
    const treasuryThresholdForInitiatorVotingPower = await deciderVotingPower.getAbsoluteThresholdByNumerator(treasuryThresholdForInitiatorNumerator);
    // the distribution was equal, let's see the absolute value of voting power for one holder
    const holderAmountOfVotingPower = await deciderVotingPower.getVoterVotingPower(addresses[1]);
    // ensure that current threshold is reachable by holder
    expect(holderAmountOfVotingPower.gt(treasuryThresholdForInitiatorVotingPower)).to.be.true;

    // current threshold is 0.5%, let's increase to 3% - this way current holders
    // will not be able to create treasury proposals until they will not increase
    // their voting power by staking or receiving delegated vp

    // creation of governance proposal to increase threshold:
    // changeThresholdForInitiator is 4 action in governanceActions enum
    // callData is bytes (encoded string module name and uint256 new value)
    const callData = ethers.utils.defaultAbiCoder.encode(
      ['string','uint256'],
      ["treasury", 300]
    );
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(4, callData);

    await expect(habitatDiamond.createGovernanceProposal(4, callData))
      .to.emit(habitatDiamond, "ProposalCreated")
      .withArgs('governance', proposalId);

    const activeGovernanceProposals = await habitatDiamond.getModuleActiveProposalsIds('governance');
    expect(activeGovernanceProposals).to.deep.include(proposalId);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(1, true))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(1, true))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[3], 'governance', proposalId, true);

    // let's check that we have enough votes for proposal to be accepted
    // first we can get absolute amount of voting power that is required for
    // proposal to be accepted
    const thresholdForProposalNumerator = await habitatDiamond.thresholdForProposalNumerator('governance');
    const amountOfVotingPowerRequiredToAcceptGovernanceProposal = await deciderVotingPower.getAbsoluteThresholdByNumerator(thresholdForProposalNumerator);
    // then we are getting current amount of yes votes (skipped: if amount of votes no is more - proposal will be rejected)
    const amountOfVotesYes = await deciderVotingPower.getProposalVotingVotesYes(
      'governance',
      1
    );
    expect(amountOfVotesYes).to.be.at.least(amountOfVotingPowerRequiredToAcceptGovernanceProposal);

    // let's accept proposal (moving in future is required)
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp('governance', proposalId);

    await helpers.time.increaseTo(votingDeadline);

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface(["function changeThresholdForInitiator(string,uint256)"]);
    const validCallData = iface.encodeFunctionData(
      'changeThresholdForInitiator',
      [
        "treasury",
        300
      ]
    );
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, "ProposalAccepted")
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.getModuleProposal("governance",proposalId);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    // let execute
    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, "ProposalExecutedSuccessfully")
      .withArgs('governance', proposalId);

    // let's check that the value we wanted to change has changed
    const currentTreasuryThresholdForInitiatorNumerator = await habitatDiamond.thresholdForInitiatorNumerator("treasury");
    expect(currentTreasuryThresholdForInitiatorNumerator.eq(300)).to.be.true;

    // CHECK EFFECTS

    // let's prove that holder 4 is not able to create treasury proposal
    // after threshold was changed from 0.5% to 3%
    await expect(habitatDiamond.connect(accounts[4]).createTreasuryProposal(addresses[4],0,'0x'))
      .to.be.revertedWith("Not enough voting power to create proposal.");
  });

  it('Governance module(VP): test changeThresholdForProposal governance method', async function () {
    const {habitatDiamond, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);
    // testing our Governance module functionality
    // we try to change value of specific data of decision type Voting Power
    // value is threshold for proposal (description: "Value is the percentage (34% - 0.34 * 10000). The percentage helps to calculate the thresholdForProposal by multiplying with maxAmountOfVotingPower (or with totalAmountOfVotingPower if it is more). Absolute value is used as a restriction for accepting proposals (comparison: if votesYes and/or votesNo more than a value - proposal reached threshold, if votesYes more than votesNo - proposal is accepted, otherwise is rejected.)"
    // testing case:
    //   Governance module - which currently has Voting Power as decision type
    //   which after proposal will be executed will have immediate effect on Governance
    //   decision process (if we increase/decrease value more/less voting power
    //   is needed for yes/no votes for proposal to be accepted/rejected)
    // notice: if we try to change this value for LaunchPad
    //   which currently has Signers as decision type after proposal will be executed
    //   will not have immediate effect on Module manager decision process
    //   and only would have if it's decision type
    //   would be changed to Voting Power by Module Manager functionality

    // this value (percentage) we try to change
    const governanceThresholdForProposalNumerator = await habitatDiamond.thresholdForProposalNumerator("governance");
    // set in initParams and was used in deployment
    expect(governanceThresholdForProposalNumerator.eq(1000)).to.be.true;

    // let's get absolute value of voting power
    const governanceThresholdForProposalVotingPower = await deciderVotingPower.getAbsoluteThresholdByNumerator(governanceThresholdForProposalNumerator);
    const signerAmountOfVotingPower = await deciderVotingPower.getVoterVotingPower(addresses[0]);
    // ensure that current threshold is not reachable only by our signer,
    // because current threshold is 10%, signer has only 5% (need others votes)
    expect(signerAmountOfVotingPower.lt(governanceThresholdForProposalVotingPower)).to.be.true;

    // current threshold is 10%, let's decrease to 5% - this way our signer
    // will be able to accept governance proposals by himself
    // if others holders with more than 5% of voting power will not vote
    // against his proposals (otherwise proposals will be rejected)

    // creation of governance proposal to decrease threshold:
    // changeThresholdForProposal is 5 action in governanceActions enum
    // callData is bytes (encoded string module name and uint256 new value)
    const callData = ethers.utils.defaultAbiCoder.encode(
      ['string','uint256'],
      ["governance", 500]
    );
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(5, callData);

    await expect(habitatDiamond.createGovernanceProposal(5, callData))
      .to.emit(habitatDiamond, "ProposalCreated")
      .withArgs('governance', proposalId);

    const activeGovernanceProposals = await habitatDiamond.getModuleActiveProposalsIds('governance');
    expect(activeGovernanceProposals).to.deep.include(proposalId);

    // let's prove that governance proposal now with 10% threshold value
    // can not be accepted by 5% votes that our signer has
    const signerVoted = await deciderVotingPower.isHolderVotedForProposal("governance", proposalId, addresses[0]);
    expect(signerVoted).to.be.true;
    const amountOfVotesYes = await deciderVotingPower.getProposalVotingVotesYes("governance", proposalId);
    const proposalThresholdReached = await deciderVotingPower.isProposalThresholdReached(amountOfVotesYes, governanceThresholdForProposalNumerator);
    expect(proposalThresholdReached).to.be.false;

    // let's give more votes to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[3], 'governance', proposalId, true);

    // let's accept proposal (moving in future is required)
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp('governance', proposalId);

    await helpers.time.increaseTo(votingDeadline);

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface(["function changeThresholdForProposal(string,uint256)"]);
    const validCallData = iface.encodeFunctionData(
      'changeThresholdForProposal',
      [
        "governance",
        500
      ]
    );
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, "ProposalAccepted")
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.getModuleProposal("governance",proposalId);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    // let execute
    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, "ProposalExecutedSuccessfully")
      .withArgs('governance', proposalId);

    // let's check that the value we wanted to change has changed
    const currentGovernanceThresholdForProposalNumerator = await habitatDiamond.thresholdForProposalNumerator("governance");
    expect(currentGovernanceThresholdForProposalNumerator.eq(500)).to.be.true;

    // CHECK EFFECTS

    // let's prove that our signer now is able to accept governance proposals
    // by himself (as he has 5% of voting power and threshold is also 5%)
    // signer will execute proposal to change the value back to 10%
    // he resigns to have so much power inside the DAO ;)
    const anotherCallData = ethers.utils.defaultAbiCoder.encode(
      ['string','uint256'],
      ["governance", 1000]
    );
    const proposalID = await habitatDiamond.callStatic.createGovernanceProposal(5, anotherCallData);

    await expect(habitatDiamond.createGovernanceProposal(5, anotherCallData))
      .to.emit(habitatDiamond, "ProposalCreated")
      .withArgs('governance', proposalID);

    // move in time and accept
    const newVotingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp('governance', proposalID);
    await helpers.time.increaseTo(newVotingDeadline);
    const newValidCallData = iface.encodeFunctionData(
      'changeThresholdForProposal',
      [
        "governance",
        1000
      ]
    );
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalID))
      .to.emit(habitatDiamond, "ProposalAccepted")
      .withArgs('governance', proposalID, governanceMethods, 0, newValidCallData);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const newProposal = await habitatDiamond.getModuleProposal("governance",proposalID);
    await helpers.time.increaseTo(newProposal.executionTimestamp);

    // let execute
    await expect(habitatDiamond.executeGovernanceProposal(proposalID))
      .to.emit(habitatDiamond, "ProposalExecutedSuccessfully")
      .withArgs('governance', proposalID);

    // let's check that the value we wanted to change has changed again
    const newCurrentGovernanceThresholdForProposalNumerator = await habitatDiamond.thresholdForProposalNumerator("governance");
    expect(newCurrentGovernanceThresholdForProposalNumerator.eq(1000)).to.be.true;
  });

  it('Governance module(VP): test changeSecondsProposalVotingPeriod governance method', async function () {
    const {habitatDiamond, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);
    // testing our Governance module functionality
    // we try to change value of specific data of decision type Voting Power
    // value is secondsProposalVotingPeriod (description: "Value represents the time in seconds that is given for voting yes or no for proposals (no voting after expired). After proposal is created the countdown started, votingPowerHolder are able to vote. After voting period is ended the proposal can be accepted or rejected depending on the voting results."
    // testing case:
    //   Governance module - which currently has Voting Power as decision type
    //   which after proposal will be executed will have immediate effect on Governance
    //   decision process (if we increase/decrease value more/less time is given for
    //   voting power holders to make their decision on specific proposal)
    // notice: if we try to change this value for Module manager
    //   which currently has Signers as decision type after proposal will be executed
    //   will not have immediate effect on Module manager decision process
    //   and only would have if it's decision type
    //   would be switched to Voting Power by Module Manager functionality

    // this value (seconds) we try to change
    const governanceSecondsProposalVotingPeriod = await habitatDiamond.getSecondsProposalVotingPeriod("governance");
    // was set in initParams.json
    expect(governanceSecondsProposalVotingPeriod.eq(604800)).to.be.true;

    // current voting period for governance is 7 days, let's decrease to 0 seconds
    // this way current holders will not be able to vote for proposals,
    // only initiator votes will be counted - if he has enough voting power
    // to reach proposal threshold then he is able to accept->execute proposal
    // if not the proposal can only be rejected (exception: the case where someone that has significant amount of vp and is clever enough to read and analize the mempool (looks like the case on optimism, although each tx is a block, tens of txs have same timestamp) and has the ability to put his tx in the same timestamp)
    // if there is no holder with enough voting power governance will stuck until
    // someone gets enough voting power by staking or receiving delegated vp
    // which will make no need in others to execute governance proposals

    // creation of governance proposal to decrease voting period (set 0 seconds):
    // changeSecondsProposalVotingPeriod is 6 action in governanceActions enum
    // callData is bytes (encoded string module name and uint256 new value)
    const callData = ethers.utils.defaultAbiCoder.encode(
      ['string','uint256'],
      ["governance", 0]
    );
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(6, callData);

    await expect(habitatDiamond.createGovernanceProposal(6, callData))
      .to.emit(habitatDiamond, "ProposalCreated")
      .withArgs('governance', proposalId);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(1, true))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(1, true))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[3], 'governance', proposalId, true);

    let isVotingEnded = await deciderVotingPower.isVotingForProposalEnded("governance", proposalId);
    expect(isVotingEnded).to.be.false;
    // let's prove that we cannot accept proposal until voting period is not ended
    // we have to wait the time in seconds (our previous value, which is 7 days)
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.be.revertedWith("Voting period is not ended yet.");

    // let's move in future and accept proposal
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp('governance', proposalId);
    await helpers.time.increaseTo(votingDeadline);

    isVotingEnded = await deciderVotingPower.isVotingForProposalEnded("governance", proposalId);
    expect(isVotingEnded).to.be.true;

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface(["function changeSecondsProposalVotingPeriod(string,uint256)"]);
    const validCallData = iface.encodeFunctionData(
      'changeSecondsProposalVotingPeriod',
      [
        "governance",
        0
      ]
    );
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, "ProposalAccepted")
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.getModuleProposal("governance",proposalId);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    // let execute
    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, "ProposalExecutedSuccessfully")
      .withArgs('governance', proposalId);

    // let's check that the value we wanted to change has changed
    const currentGovernanceSecondsProposalVotingPeriod = await habitatDiamond.getSecondsProposalVotingPeriod("governance");
    expect(currentGovernanceSecondsProposalVotingPeriod.eq(0)).to.be.true;

    // CHECK EFFECTS

    // let's prove that we don't need to jump in a future anymore to accept proposal
    // as our signer doesn't have enough vp the proposal could be only rejected
    const callData2 = ethers.utils.defaultAbiCoder.encode(
      ['string','uint256'],
      ["governance", 604800]
    );
    const proposalId2 = await habitatDiamond.callStatic.createGovernanceProposal(6, callData2);

    await expect(habitatDiamond.createGovernanceProposal(6, callData2))
      .to.emit(habitatDiamond, "ProposalCreated")
      .withArgs('governance', proposalId2);

    isVotingEnded = await deciderVotingPower.isVotingForProposalEnded(
      "governance",
      proposalId2
    );
    expect(isVotingEnded).to.be.true;

    // let's try to decide on proposal
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId2, true))
      .to.be.revertedWith("Voting period is ended.");


    const validCallData2 = iface.encodeFunctionData(
      'changeSecondsProposalVotingPeriod',
      [
        "governance",
        604800
      ]
    );
    // let's reject the proposal
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId2))
      .to.emit(habitatDiamond, "ProposalRejected")
      .withArgs('governance', proposalId2, governanceMethods, 0, validCallData2);
  });

  it('Governance module(VP): test changeSecondsProposalExecutionDelayPeriodVP governance method', async function () {
    const {habitatDiamond, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);
    // testing our Governance module functionality
    // we try to change value of specific data of decision type Voting Power
    // value is secondsProposalExecutionDelayPeriodVP (description: "Value represents the time in seconds that is given for a delaying execution after voting period is ended."
    // testing case:
    //   Governance module - which currently has Voting Power as decision type
    //   which after proposal will be executed will have immediate effect on Governance
    //   decision process (if we increase/decrease value more/less time is required
    //   to wait after voting is ended to be able to execute the proposal)
    // notice: if we try to change this value for Module manager
    //   which currently has Signers as decision type after proposal will be executed
    //   will not have immediate effect on Module manager decision process
    //   and only would have if it's decision type
    //   would be switched to Voting Power by Module Manager functionality

    // this value (seconds) we try to change
    const governanceSecondsProposalExecutionDelayPeriodVP = await habitatDiamond.getSecondsProposalExecutionDelayPeriodVP("governance");
    // was set in initParams.json
    expect(governanceSecondsProposalExecutionDelayPeriodVP.eq(43200)).to.be.true;

    // current execution delay period for governance is 12 hours, let's decrease to 0 seconds
    // this way accepted proposals will be executed right after voting period is ended,
    // meaning that the someone who somehow gets a lot of voting power is able to
    // change the voting proportion in a last second and immediately execute proposal
    // which opens the ability for attack vectors (like flashloan attacks)

    // creation of governance proposal to decrease execution delay period (set 0 seconds):
    // changeSecondsProposalExecutionDelayPeriodVP is 7 action in governanceActions enum
    // callData is bytes (encoded string module name and uint256 new value)
    const callData = ethers.utils.defaultAbiCoder.encode(
      ['string','uint256'],
      ["governance", 0]
    );
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(7, callData);

    await expect(habitatDiamond.createGovernanceProposal(7, callData))
      .to.emit(habitatDiamond, "ProposalCreated")
      .withArgs('governance', proposalId);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[3], 'governance', proposalId, true);

    // let's move in future and accept proposal
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp('governance', proposalId);
    await helpers.time.increaseTo(votingDeadline);

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface(["function changeSecondsProposalExecutionDelayPeriodVP(string,uint256)"]);
    const validCallData = iface.encodeFunctionData(
      'changeSecondsProposalExecutionDelayPeriodVP',
      [
        "governance",
        0
      ]
    );
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, "ProposalAccepted")
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    let acceptedGovernanceProposals = await habitatDiamond.getModuleAcceptedProposalsIds("governance");
    expect(acceptedGovernanceProposals).to.deep.include(proposalId)

    // execute the proposal
    // our value is important at this step (right after acceptance)
    // lets prove that we are not able to execute right away as our value is non-zero
    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.be.revertedWith("Wait until proposal delay time is expired.");
    // let's jump into a future through our value (which is our delay in seconds)
    await helpers.time.increase(governanceSecondsProposalExecutionDelayPeriodVP);
    // we are in a future, let's try to execute
    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, "ProposalExecutedSuccessfully")
      .withArgs('governance', proposalId);

    // let's check that the value we wanted to change has changed
    const currentGovernanceSecondsProposalExecutionDelayPeriodVP = await habitatDiamond.getSecondsProposalExecutionDelayPeriodVP("governance");
    expect(currentGovernanceSecondsProposalExecutionDelayPeriodVP.eq(0)).to.be.true;

    // CHECK EFFECTS

    // let's prove that we don't need to wait any delay to execute proposals
    const callData2 = ethers.utils.defaultAbiCoder.encode(
      ['string','uint256'],
      ["governance", 43200]
    );
    const proposalId2 = await habitatDiamond.callStatic.createGovernanceProposal(7, callData2);

    await expect(habitatDiamond.createGovernanceProposal(7, callData2))
      .to.emit(habitatDiamond, "ProposalCreated")
      .withArgs('governance', proposalId2);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId2, true))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[2], 'governance', proposalId2, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(proposalId2, true))
      .to.emit(deciderVotingPower, "Voted")
      .withArgs(addresses[3], 'governance', proposalId2, true);

    const validCallData2 = iface.encodeFunctionData(
      'changeSecondsProposalExecutionDelayPeriodVP',
      [
        "governance",
        43200
      ]
    );
    // let's move in future and accept proposal
    const votingDeadline2 = await deciderVotingPower.getProposalVotingDeadlineTimestamp('governance', proposalId2);
    await helpers.time.increaseTo(votingDeadline2);

    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId2))
      .to.emit(habitatDiamond, "ProposalAccepted")
      .withArgs('governance', proposalId2, governanceMethods, 0, validCallData2);

    // proposal is accepted
    acceptedGovernanceProposals = await habitatDiamond.getModuleAcceptedProposalsIds("governance");
    expect(acceptedGovernanceProposals).to.deep.include(proposalId2)

    // now as our delay period is 0 we don't need to wait and executing right away
    await expect(habitatDiamond.executeGovernanceProposal(proposalId2))
      .to.emit(habitatDiamond, "ProposalExecutedSuccessfully")
      .withArgs('governance', proposalId2);

    // let's check that the value was changed again
    const currentGovernanceSecondsProposalExecutionDelayPeriodVP2 = await habitatDiamond.getSecondsProposalExecutionDelayPeriodVP("governance");
    expect(currentGovernanceSecondsProposalExecutionDelayPeriodVP2.eq(43200)).to.be.true;
  });

  it('Governance module(VP): test changeSecondsProposalExecutionDelayPeriodSigners governance method', async function () {
    const {habitatDiamond, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);

  });

  it('Governance module(VP): test changeDecisionData governance method', async function () {
    const {habitatDiamond, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);

  });

  it('Governance module/Voting Power: should be able to execute updateFacet governance proposal', async function () {
    const {habitatDiamond, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);

  });

  it('Governance module/Voting Power: should be able to execute updateFacetAndState governance proposal', async function () {
    const {habitatDiamond, deciderVotingPower, accounts, addresses} = await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);
    // all methods that must be executed:
    // write it() for each method
    // changeDecisionData - as it is general one, we can use it as just adding new decision type
    // changeThresholdForInitiator
    // changeThresholdForProposal
    // changeSecondsProposalVotingPeriod
    // changeSecondsProposalExecutionDelayPeriodVP
    // changeSecondsProposalExecutionDelayPeriodSigners
  });


});
