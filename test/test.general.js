const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const { deployDiamond } = require("../scripts/deployHabitatDAO.js");
const { getContractsForUniV3, getWETH } = require('./helpers/getContractsForUniV3.js');

describe('HabitatDiamond', function () {
  async function deployHabitatDAOFixture() {
    const accounts = await ethers.getSigners();
    signer = accounts[0];
    const [habitatAddress, habitatABI, initialDistributorAddress, stakeContractAddress] = await deployDiamond();
    const habitatDiamond = new ethers.Contract(habitatAddress, habitatABI, signer);
    const initialDistributor = await ethers.getContractAt('InitialDistributorAbleToStake', initialDistributorAddress, signer);
    const stakeERC20Contract = await ethers.getContractAt('StakeContractERC20UniV3', stakeContractAddress, signer);
    const addresses = accounts.map((val) => {
      return val.address;
    });
    return {habitatDiamond, initialDistributor, stakeERC20Contract, accounts, addresses};
  }

  async function deployHabitatDAOAndDistributeFixture() {
    const {habitatDiamond, initialDistributor, stakeERC20Contract, accounts, addresses} = await helpers.loadFixture(deployHabitatDAOFixture);
    // paste distribute logic
    const hbtTotalSupply = await habitatDiamond.totalSupply();
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

    return {habitatDiamond, stakeERC20Contract, accounts, addresses, weth};
  }

  it('should distribute tokens', async function () {
    const {habitatDiamond, initialDistributor, stakeERC20Contract, addresses} = await helpers.loadFixture(deployHabitatDAOFixture);
    const hbtTotalSupply = await habitatDiamond.totalSupply();
    let initialDistributorBalance = await habitatDiamond.balanceOf(initialDistributor.address);
    expect(initialDistributorBalance).to.eq(hbtTotalSupply);

    let stakeContractBalance = await habitatDiamond.balanceOf(stakeERC20Contract.address);
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
      const balance = await habitatDiamond.balanceOf(addresses[i]);
      expect(balance).to.eq(shareOfHalfOfTokens);
    }
    initialDistributorBalance = await habitatDiamond.balanceOf(initialDistributor.address);
    expect(initialDistributorBalance).to.eq(hbtTotalSupply.sub(halfOfTokens));
    // stake tokens in favor of addresses
    tx = await initialDistributor.stakeTokensInFavorOfMultipleAddresses(addresses, Array(addresses.length).fill(shareOfHalfOfTokens), halfOfTokens);
    receipt = await tx.wait()

    initialDistributorBalance = await habitatDiamond.balanceOf(initialDistributor.address);
    assert(initialDistributorBalance.isZero(), 'initial distributor at this point must be empty');

    stakeContractBalance = await habitatDiamond.balanceOf(stakeERC20Contract.address);
    expect(stakeContractBalance).to.eq(halfOfTokens);

    for (let i = 0; i < addresses.length; i++) {
      // first check stake contract effects
      const stakedBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(addresses[i]);
      expect(stakedBalance).to.eq(shareOfHalfOfTokens);
      // second check dao contract effects
      const votingPower = await habitatDiamond.getVoterVotingPower(addresses[i]);
      expect(votingPower).to.eq(stakedBalance);
    }
  });

  it('should be able to stake/unstake governance token', async function () {
    const {habitatDiamond, stakeERC20Contract, accounts, addresses} = await helpers.loadFixture(deployHabitatDAOAndDistributeFixture);
    const amountToStakeUnstake = await habitatDiamond.balanceOf(addresses[0]);
    // when stake/unstake totalAmountOfVotingPower increase/decrease
    const totalAmountOfVotingPowerBeforeStaking = await habitatDiamond.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerBeforeStaking.gt(0)).to.be.true;
    // should stake
    for (let i = 1; i < addresses.length; i++) {
      let tokenBalance = await habitatDiamond.balanceOf(addresses[i]);
      expect(tokenBalance).eq(amountToStakeUnstake);
      const stakeERC20ContractNewSigner = stakeERC20Contract.connect(accounts[i]);
      const habitatDiamondNewSigner = habitatDiamond.connect(accounts[i]);
      // first give allowance to stake contract
      let tx = await habitatDiamondNewSigner.approve(stakeERC20Contract.address, tokenBalance);
      await tx.wait();
      const allowedAmount = await habitatDiamond.allowance(addresses[i], stakeERC20Contract.address);
      expect(allowedAmount).to.eq(tokenBalance);
      // second stake
      tx = await stakeERC20ContractNewSigner.stakeGovToken(amountToStakeUnstake);
      await tx.wait();
      // confirm effects
      tokenBalance = await habitatDiamond.balanceOf(addresses[i]);
      expect(tokenBalance.isZero()).to.be.true;
      const stakedERC20GovTokenBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(addresses[i]);
      expect(stakedERC20GovTokenBalance.gte(amountToStakeUnstake)).to.be.true;
      const currentTotalAmountOfVotingPower = await habitatDiamond.getTotalAmountOfVotingPower();
      expect(currentTotalAmountOfVotingPower).to.eq(totalAmountOfVotingPowerBeforeStaking.add(amountToStakeUnstake.mul(i)));
      const votingPower = await habitatDiamond.getVoterVotingPower(addresses[i]);
      expect(votingPower.gte(amountToStakeUnstake)).to.be.true;
    }
    // should unstake
    const totalAmountOfVotingPowerAfterStaking = await habitatDiamond.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerAfterStaking.gt(0)).to.be.true;
    for (let i = 1; i < addresses.length; i++) {
      const votingPower = await habitatDiamond.getVoterVotingPower(addresses[i]);
      const stakedERC20GovTokenBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(addresses[i]);
      const tokenBalance = await habitatDiamond.balanceOf(addresses[i]);

      const stakeERC20ContractNewSigner = stakeERC20Contract.connect(accounts[i]);
      // first check if able to unstake
      const unstakeTimestamp = await habitatDiamond.getTimestampToUnstake(addresses[i]);
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
      const votingPowerAfterUnstake = await habitatDiamond.getVoterVotingPower(addresses[i]);
      expect(votingPowerAfterUnstake).eq(votingPower.sub(amountToStakeUnstake));
      const stakedERC20GovTokenBalanceAfterUnstake = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(addresses[i]);
      expect(stakedERC20GovTokenBalanceAfterUnstake).eq(stakedERC20GovTokenBalance.sub(amountToStakeUnstake));
      const tokenBalanceAfterUnstake = await habitatDiamond.balanceOf(addresses[i]);
      expect(tokenBalanceAfterUnstake).eq(tokenBalance.add(amountToStakeUnstake));
    }
  });

  it('should be able to stake/unstake NFT position', async function () {
    const {habitatDiamond, stakeERC20Contract, accounts} = await helpers.loadFixture(deployHabitatDAOAndDistributeFixture);
    const newSigner = accounts[2];
    const habitatDiamondNewSigner = habitatDiamond.connect(newSigner);
    const stakeERC20ContractNewSigner = stakeERC20Contract.connect(newSigner);
    const fee = 3000;
    const tickSpacing = 60;
    const {weth, nfPositionManager, pool} = getContractsForUniV3(habitatDiamond.address, fee, newSigner);
    // first provide liquidity
    // prepare mintParams
    const block = await ethers.provider.getBlock('latest');
    const isHBTToken0 = ethers.BigNumber.from(habitatDiamond.address).lt(ethers.BigNumber.from(weth.address));
    const slot0 = await pool.slot0();

    const tickLower = slot0.tick - (slot0.tick % tickSpacing);
    const tickUpper = tickLower + tickSpacing;
    const mintParams = {
      token0: isHBTToken0 ? habitatDiamond.address : weth.address,
      token1: isHBTToken0 ? weth.address : habitatDiamond.address,
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

    tx = await habitatDiamondNewSigner.approve(nfPositionManager.address, ethers.constants.WeiPerEther.mul(10000));
    await tx.wait();
    const habitatAllowedAmount = await habitatDiamondNewSigner.allowance(newSigner.address, nfPositionManager.address);
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
    expect(position.token0).to.eq(isHBTToken0 ? habitatDiamond.address : weth.address);
    expect(position.token1).to.eq(isHBTToken0 ? weth.address : habitatDiamond.address);

    // stake NFTposition
    const votingPowerBeforeStake = await habitatDiamond.getVoterVotingPower(newSigner.address);
    const totalAmountOfVotingPowerBeforeStaking = await habitatDiamond.getTotalAmountOfVotingPower();

    tx = await stakeERC20ContractNewSigner.stakeUniV3NFTPosition(tokenId);
    await tx.wait();
    // confirm effects
    let newOwnerOfNFTposition = await nfPositionManager.ownerOf(tokenId);
    expect(newOwnerOfNFTposition).to.eq(stakeERC20ContractNewSigner.address);
    let isStakedByHolder = await stakeERC20Contract.nftPositionIsStakedByHolder(newSigner.address, tokenId);
    expect(isStakedByHolder).to.be.true;
    // maybe write pure function that returns the amount without staking?
    const amountOfVotingPowerForNFT = await stakeERC20Contract.getAmountOfVotingPowerForNFTPosition(tokenId);
    const votingPowerAfterStake = await habitatDiamond.getVoterVotingPower(newSigner.address);
    expect(votingPowerAfterStake).to.eq(votingPowerBeforeStake.add(amountOfVotingPowerForNFT));
    const totalAmountOfVotingPowerAfterStaking = await habitatDiamond.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerAfterStaking).to.eq(totalAmountOfVotingPowerBeforeStaking.add(amountOfVotingPowerForNFT));

    // unstake nft position
    const unstakeTimestamp = await habitatDiamond.getTimestampToUnstake(newSigner.address);
    // no voting happened (rare case) must be 0
    expect(unstakeTimestamp.isZero()).to.be.true;
    tx = await stakeERC20ContractNewSigner.unstakeUniV3NFTPosition(tokenId);
    await tx.wait();
    // confirm effects
    const totalAmountOfVotingPowerAfterUnstake = await habitatDiamond.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerAfterUnstake).to.eq(totalAmountOfVotingPowerBeforeStaking);
    const votingPowerAfterUnstake = await habitatDiamond.getVoterVotingPower(newSigner.address);
    expect(votingPowerAfterUnstake).to.eq(votingPowerBeforeStake);
    isStakedByHolder = await stakeERC20Contract.nftPositionIsStakedByHolder(newSigner.address, tokenId);
    expect(isStakedByHolder).to.be.false;
    newOwnerOfNFTposition = await nfPositionManager.ownerOf(tokenId);
    expect(newOwnerOfNFTposition).to.eq(newSigner.address);
  });

  it('should be able to delegate/undelegate', async function () {
    const {habitatDiamond, stakeERC20Contract, accounts} = await helpers.loadFixture(deployHabitatDAOAndDistributeFixture);
    const delegator = accounts[1];
    const habitatDiamondDelegator = habitatDiamond.connect(delegator);
    const delegatee = accounts[2];
    const delegatorVotingPowerBefore = await habitatDiamond.getVoterVotingPower(delegator.address);
    expect(delegatorVotingPowerBefore.gt(0)).to.be.true;
    const delegateeVotingPowerBefore = await habitatDiamond.getVoterVotingPower(delegatee.address);
    // delegate
    let tx = await habitatDiamondDelegator.delegateVotingPower(delegatee.address);
    await tx.wait();
    const delegatorVotingPowerAfter = await habitatDiamond.getVoterVotingPower(delegator.address);
    expect(delegatorVotingPowerAfter.isZero()).to.be.true;
    const delegateeVotingPowerAfter = await habitatDiamond.getVoterVotingPower(delegatee.address);
    expect(delegateeVotingPowerAfter).to.eq(delegateeVotingPowerBefore.add(delegatorVotingPowerBefore));
    const delegateeCorrect = await habitatDiamond.getDelegatee(delegator.address);
    expect(delegateeCorrect).to.eq(delegatee.address);
    const delegatedVotingPower = await habitatDiamond.getAmountOfDelegatedVotingPower(delegator.address);
    expect(delegatedVotingPower).to.eq(delegatorVotingPowerBefore);
    // undelegate
    tx = await habitatDiamondDelegator.undelegateVotingPower();
    await tx.wait();
    const delegatorVotingPowerUndelegated = await habitatDiamond.getVoterVotingPower(delegator.address);
    expect(delegatorVotingPowerUndelegated).to.eq(delegatorVotingPowerBefore);
    const delegateeVotingPowerUndelegated = await habitatDiamond.getVoterVotingPower(delegatee.address);
    expect(delegateeVotingPowerUndelegated).to.eq(delegateeVotingPowerBefore);
  });

  it('should be able to create treasury proposal', async function () {
    const {habitatDiamond, stakeERC20Contract, accounts, addresses, weth} = await helpers.loadFixture(deployHabitatDAOAndDistributeFixture);
    const ten = ethers.constants.WeiPerEther.mul(10);
    // first lets make voting power 0 and try to create treasury proposal
    const unstaker = accounts[1];
    const beneficiar = addresses[3];
    expect(await habitatDiamond.callStatic.isEnoughVotingPower(unstaker.address, 'treasury'))
      .to.be.true;
    const stakedBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(unstaker.address);
    const stakeERC20ContractUnstaker = stakeERC20Contract.connect(unstaker);
    const habitatDiamondUnstaker = habitatDiamond.connect(unstaker);
    let tx = await stakeERC20ContractUnstaker.unstakeGovToken(stakedBalance);
    await tx.wait();
    const unstakerVotingPower = await habitatDiamond.getVoterVotingPower(unstaker.address);
    expect(unstakerVotingPower.isZero()).to.be.true;
    expect(await habitatDiamond.callStatic.isEnoughVotingPower(unstaker.address, 'treasury'))
      .to.be.false;
    await expect(habitatDiamondUnstaker.createTreasuryProposal(unstaker.address, ten, '0x'))
      .to.be.revertedWith("Not enough voting power to create proposal.");

    // second lets try to create a proposal that is calling diamond itself
    await expect(habitatDiamond.createTreasuryProposal(habitatDiamond.address, '0x0', '0x11223344'))
      .to.be.revertedWith("Treasury proposals are related only to governance token.");

    // third lets try create a proposal to transfer HBT tokens from treasury
    let callData = habitatDiamond.interface.encodeFunctionData('transfer', [beneficiar, ten.mul(1000)]);
    const proposalId = await habitatDiamond.callStatic.createTreasuryProposal(habitatDiamond.address, '0x0', callData);
    expect(proposalId).to.eq(ethers.constants.One);

    // lets create proposal to transfer ETH
    const treasuryExecutionDelay = await habitatDiamond.callStatic.getSecondsProposalExecutionDelayPeriod('treasury');
    const treasuryVotingPeriod = await habitatDiamond.callStatic.getSecondsProposalVotingPeriod('treasury');
    const proposalIDToTransferETH = await habitatDiamond.callStatic.createTreasuryProposal(beneficiar, ten, '0x');
    let currentBlock = await ethers.provider.getBlock('latest');
    await expect(habitatDiamond.createTreasuryProposal(beneficiar, ten, '0x'))
      .to.emit(habitatDiamond, "TreasuryProposalCreated")
      .withArgs(proposalIDToTransferETH, treasuryVotingPeriod.add(currentBlock.timestamp + 1))

    let proposal = await habitatDiamond.callStatic.getTreasuryProposal(proposalIDToTransferETH);
    expect(proposal.proposalAccepted).to.be.false;
    expect(proposal.destinationAddress).to.eq(beneficiar);
    expect(proposal.value).to.eq(ten);
    expect(proposal.callData).to.eq('0x');
    expect(proposal.proposalExecuted).to.be.false;
    expect(proposal.executionTimestamp).to.eq(treasuryVotingPeriod.add(currentBlock.timestamp + 1).add(treasuryExecutionDelay));

    // lets create proposal to transfer WETH
    callData = weth.interface.encodeFunctionData('transfer', [beneficiar, ten]);
    const proposalIDToTransferWETH = (await habitatDiamond.callStatic.getTreasuryProposalsCount()).add(1);
    currentBlock = await ethers.provider.getBlock('latest');
    await expect(habitatDiamond.createTreasuryProposal(weth.address, '0x0', callData))
      .to.emit(habitatDiamond, "TreasuryProposalCreated")
      .withArgs(proposalIDToTransferWETH, treasuryVotingPeriod.add(currentBlock.timestamp + 1))

    proposal = await habitatDiamond.callStatic.getTreasuryProposal(proposalIDToTransferWETH);
    expect(proposal.proposalAccepted).to.be.false;
    expect(proposal.destinationAddress).to.eq(weth.address);
    expect(proposal.value.isZero()).to.be.true;
    expect(proposal.callData).to.eq(callData);
    expect(proposal.proposalExecuted).to.be.false;
    expect(proposal.executionTimestamp).to.eq(treasuryVotingPeriod.add(currentBlock.timestamp + 1).add(treasuryExecutionDelay));
  });

  it('should be able to decide on treasury proposal', async function () {
    const {habitatDiamond, stakeERC20Contract, accounts, addresses} = await helpers.loadFixture(deployHabitatDAOAndDistributeFixture);
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
    let activeVotingProposalIds = await habitatDiamond.callStatic.getTreasuryActiveVotingProposalsIds();
    expect(activeVotingProposalIds.some((id) => id.eq(proposalID))).to.be.true;
    // the initiator already voted
    expect(await habitatDiamond.callStatic.isHolderVotedForProposal('treasury', proposalID, addresses[0]))
      .to.be.true;
    const initiatorVotingPower = await habitatDiamond.getVoterVotingPower(accounts[0].address);
    let votesYes = await habitatDiamond.callStatic.getProposalVotingVotesYes('treasury', proposalID);
    expect(votesYes).to.eq(initiatorVotingPower);

    // make sure voting started
    expect(await habitatDiamond.callStatic.isVotingForProposalStarted('treasury', proposalID))
      .to.be.true;
    const votingDeadline = await habitatDiamond.callStatic.getProposalVotingDeadlineTimestamp('treasury', proposalID);
    const currentBlock = await ethers.provider.getBlock('latest');
    expect(votingDeadline.gt(currentBlock.timestamp)).to.be.true;

    // lets decide
    const voteYes = ethers.utils.defaultAbiCoder.encode(['bool'], [true]);
    const voteNo = ethers.utils.defaultAbiCoder.encode(['bool'], [false]);
    // lets decide on non-exist proposal
    await expect(habitatDiamond.decideOnTreasuryProposal('0x12', voteYes))
      .to.be.revertedWith("No voting rn.");
    // lets decide second time
    await expect(habitatDiamond.decideOnTreasuryProposal(proposalID, voteYes))
      .to.be.revertedWith("Already voted.");
    // lets stake more govTokens, get more votingPower and decide again
    const balance = await habitatDiamond.balanceOf(addresses[0]);
    tx = await habitatDiamond.approve(stakeERC20Contract.address, balance);
    await tx.wait();
    tx = await stakeERC20Contract.stakeGovToken(balance);
    await tx.wait();
    tx = await habitatDiamond.decideOnTreasuryProposal(proposalID, voteYes);
    await tx.wait();
    votesYes = await habitatDiamond.callStatic.getProposalVotingVotesYes('treasury', proposalID);
    expect(votesYes).to.eq(initiatorVotingPower.add(balance));

    // TODO go through libraries and add abis to habitatDiamondABI
    const libVotingPowerDecisionMaking = await ethers.getContractFactory('LibVotingPowerDecisionMaking');
    await expect(habitatDiamond.connect(accounts[1]).decideOnTreasuryProposal(proposalID, voteYes))
      .to.emit(libVotingPowerDecisionMaking.attach(habitatDiamond.address), "Voted")
      .withArgs(addresses[1], 'treasury', proposalID, true);

    const votingPowerAccount1 = await habitatDiamond.getVoterVotingPower(accounts[1].address);
    expect(await habitatDiamond.callStatic.getProposalVotingVotesYes('treasury', proposalID))
      .to.eq(votesYes.add(votingPowerAccount1));

    await expect(habitatDiamond.connect(accounts[2]).decideOnTreasuryProposal(proposalID, voteNo))
      .to.emit(libVotingPowerDecisionMaking.attach(habitatDiamond.address), "Voted")
      .withArgs(addresses[2], 'treasury', proposalID, false);

    const votingPowerAccount2 = await habitatDiamond.getVoterVotingPower(accounts[2].address);
    const votesNo = await habitatDiamond.callStatic.getProposalVotingVotesNo('treasury', proposalID);
    expect(votesNo).to.eq(votingPowerAccount2);

    const thresholdForProposalReachedVotesYes = await habitatDiamond.callStatic.isProposalThresholdReached(votesYes, 'treasury');
    expect(thresholdForProposalReachedVotesYes).to.be.true;

    const thresholdForProposal = await habitatDiamond.callStatic.absoluteThresholdForProposal('treasury');
    votesYes = await habitatDiamond.callStatic.getProposalVotingVotesYes('treasury', proposalID);
    expect(thresholdForProposal.lte(votesYes)).to.be.true;

    // accept proposal
    // lets try to accept not waiting voting period
    await expect(habitatDiamond.acceptOrRejectTreasuryProposal(proposalID))
      .to.be.revertedWith("Voting period is not ended yet.");

    // lets move to timestamp when voting period is ended
    await helpers.time.increaseTo(votingDeadline);
    await expect(habitatDiamond.acceptOrRejectTreasuryProposal(proposalID))
      .to.emit(habitatDiamond, "TreasuryProposalAccepted")
      .withArgs(proposalID, beneficiar, ten, '0x');
    // confirm proposalId is removed from active
    activeVotingProposalIds = await habitatDiamond.callStatic.getTreasuryActiveVotingProposalsIds();
    expect(activeVotingProposalIds.some((id) => id.eq(proposalID))).to.be.false;
    // confirm proposal voting was removed
    votesYes = await habitatDiamond.callStatic.getProposalVotingVotesYes('treasury', proposalID);
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
      .to.emit(habitatDiamond, "TreasuryProposalExecutedSuccessfully")
      .withArgs(proposalID);

    // confirm receiving eth
    const beneficiarETHBalanceAfter = await ethers.provider.getBalance(beneficiar);
    expect(beneficiarETHBalanceBefore.add(ten)).to.eq(beneficiarETHBalanceAfter);
    const habitatDAOETHBalanceAfter = await ethers.provider.getBalance(habitatDiamond.address);
    expect(habitatDAOETHBalanceBefore.sub(ten)).to.eq(habitatDAOETHBalanceAfter);
    // TODO create proposal to transfer WETH and vote no to reject

  });
});
